package CPAN::Digger::Index;
use 5.008008;
use Moose;

our $VERSION = '0.08';

extends 'CPAN::Digger';

use autodie;
use Cwd qw(abs_path cwd);
use Capture::Tiny qw(capture);
use Data::Dumper qw(Dumper);
use File::Basename qw(basename dirname);
use File::Copy qw(copy move);
use File::Copy::Recursive qw(fcopy rcopy);
use File::Path qw(mkpath);
use File::Spec ();
use File::Temp qw(tempdir);
use File::Find::Rule ();
use File::ShareDir   ();
use JSON qw(to_json from_json);
use List::Util qw(max);
use Parse::CPAN::Whois ();

#use Parse::CPAN::Authors  ();
use POSIX                 ();
use Parse::CPAN::Packages ();
use YAML                  ();
use PPIx::EditorTools::Outline;
use Perl::Critic;
use Archive::Any;

#require Archive::Any::Plugin::Tar;
#require Archive::Any::Plugin::Zip;

use CPAN::Digger::PPI;
use CPAN::Digger::Pod;
use CPAN::Digger::DB;
use CPAN::Digger::Tools;

#has 'counter'    => (is => 'rw', isa => 'HASH');
has 'counter_distro' => ( is => 'rw', isa => 'Int', default => 0 );
has 'dir'            => ( is => 'ro', isa => 'Str' );
has 'prefix'         => ( is => 'ro', isa => 'Str' );
has 'authors'        => ( is => 'rw', isa => 'Parse::CPAN::Authors' );

has 'cpan'   => ( is => 'ro', isa => 'Str' );
has 'output' => ( is => 'ro', isa => 'Str' );
has 'filter' => ( is => 'ro', isa => 'Str' );

has 'prepare' => ( is => 'ro', isa => 'Str' );
has 'pod'     => ( is => 'ro', isa => 'Str' );
has 'syn'     => ( is => 'ro', isa => 'Str' );
has 'outline' => ( is => 'ro', isa => 'Str' );
has 'critic'  => ( is => 'ro', isa => 'Str' );

my $dbx;

sub db {
	if ( not $dbx ) {
		$dbx = CPAN::Digger::DB->new;
		$dbx->setup;
	}
	return $dbx;
}

sub process_all_distros {
	my ($self) = @_;

	my $distros = db->get_all_distros;
	LOG('start processing distros');

	#LOG(Dumper $distros);
	my $filter = $self->filter;
	foreach my $name ( sort keys %$distros ) {

		next if $filter and $name !~ qr{$filter};

		LOG("Work on $name");
		my $d       = $distros->{$name};
		my $details = db->get_distro_details_by_id( $d->{id} );
		next if $details;
		$self->process_distro( $d->{path} );
	}
	LOG('done processing all distros');

	return;
}


# process a single distribution given the (relative) path to it
sub process_distro {
	my ( $self, $path ) = @_;

	#$self->counter_distro($self->counter_distro +1);
	LOG("Working on $path");

	my $d = db->get_distro_by_path($path);
	die "Could not find distro by path '$path'" if not $d;

	my $src_dir  = File::Spec->catdir( $self->output, 'src',  uc $d->{author} );
	my $dist_dir = File::Spec->catdir( $self->output, 'dist', $d->{name} );
	my $syn_dir  = File::Spec->catdir( $self->output, 'syn',  $d->{name} );

	mkpath $_ for ( $dist_dir, $src_dir, $syn_dir );

	if ( $self->prepare ) {
		return if $d->{unzip_error};
		$self->prepare_src( $d, $src_dir, $path ) or return;
	}

	chdir $d->{distvname}; # source_dir

	my @files = File::Find::Rule->file->relative->in('.');

	my $pods = $self->generate_html_from_pod( $dist_dir, $d );

	my %data;

	$data{modules} = $pods->{modules};
	if ( @{ $pods->{pods} } ) {
		$data{pods} = $pods->{pods};
	}

	my ( $outlines, $min_versions, $pc_violations, $version_markers ) =
		$self->generate_outline( $dist_dir, $data{modules} );

	$self->generate_syn( $syn_dir, $data{modules} );

	$self->collect_meta_data( \%data );
	$data{distvname} = $d->{distvname};

	LOG( "update_distro_details for $path by " . Dumper \%data );

	my $dist = db->get_distro_by_path($path);

	#LOG("Update DB for id $dist->{id}");

	my $min_perl_version = 1;
	db->dbh->begin_work;


	# add files to database
	foreach my $f (@files) {
		db->add_file( $f, $dist->{id} );
	}

	foreach my $t ( @{ $data{modules} } ) {
		db->update_module( $t, $min_versions->{ $t->{name} }, 1, $dist->{id} );
		$min_perl_version = max( $min_versions->{ $t->{name} }, $min_perl_version );
	}
	foreach my $t ( @{ $data{pods} } ) {
		db->update_module( $t, $min_versions->{ $t->{name} }, 0, $dist->{id} );
		$min_perl_version = max( $min_versions->{ $t->{name} }, $min_perl_version );
	}

	foreach my $o (@$outlines) {

		#CPAN::Digger::Index::LOG("add subs $o->{name} " . Dumper $o);
		db->add_subs( $o->{name}, $o->{methods} );
	}
	$data{min_perl} = $min_perl_version;
	db->update_distro_details( \%data, $dist->{id} );
	{
		my $policies = db->get_all_policies;
		if (%$pc_violations) {
			my $id_of_file = db->get_file_ids_of_dist( $dist->{id} );

			#die Dumper $id_of_file;
			foreach my $file ( keys %$pc_violations ) {

				#die $file;

				if ( not $id_of_file->{$file} ) {
					warn("id of file '$file' is missing");
					next;
				}
				foreach my $v ( @{ $pc_violations->{$file} } ) {
					my $policy = substr( $v->policy, 22 );

					#print "$policy\n";
					if ( not $policies->{$policy} ) {
						$policies->{$policy} = db->add_policy($policy);
					}

					#print STDERR $id_of_file->{$file}, "\n";
					db->add_violation( $v, $id_of_file->{$file}{id}, $policies->{$policy} );
				}
			}
		}
	}
	{
		open my $out, '>', "$dist_dir/version.txt";
		print $out "<pre>\n";
		print $out "Overall min perl version: $min_perl_version\n\n";
		print $out "Markers:\n\n";
		print $out $version_markers;
		print $out "\n</pre>\n";
	}

	db->dbh->commit;

	return;
}

# assume we are in the project directory
sub collect_meta_data {
	my ( $self, $data ) = @_;

	$data->{has_meta_yml} = -e 'META.yml';

	# TODO we need to make sure the data we read from META.yml is correct and
	# someone does not try to fill it with garbage or too much data.
	if ( $data->{has_meta_yml} ) {
		eval {
			my $meta = YAML::LoadFile('META.yml');

			#print Dumper $meta;
			my @fields = qw(license abstract author name requires version);
			foreach my $field (@fields) {
				$data->{meta}{$field} = $meta->{$field};
			}
			if ( $meta->{resources} ) {
				foreach my $field (qw(repository homepage bugtracker license)) {
					$data->{meta}{resources}{$field} = $meta->{resources}{$field};
				}
			}
		};
		if ($@) {
			WARN("Exception while reading YAML file: $@");

			#$counter{exception_in_yaml}++;
			$data->{exception_in_yaml} = $@;
		}
	}
	$data->{has_meta_json} = -e 'META.json';

	if ( -d 'xt' ) {
		$data->{has_xt} = 1;
	}
	if ( -d 't' ) {
		$data->{has_t} = 1;
	}
	if ( -f 'test.pl' ) {
		$data->{test_file} = 1;
	}
	my @example_dirs = qw(eg examples);
	foreach my $dir (@example_dirs) {
		if ( -d $dir ) {
			$data->{examples} = $dir;
		}
	}
	my @changes_files = qw(Changes CHANGES ChangeLog);


	my @readme_files = qw('README');

	my @special_files =
		sort grep { -e $_ } ( qw(META.yml MANIFEST INSTALL Makefile.PL Build.PL), @changes_files, @readme_files );

	if ( $data->{meta}{resources}{repository} ) {
		my $repo = delete $data->{meta}{resources}{repository};
		$data->{meta}{resources}{repository}{display} = $repo;
		$repo =~ s{git://(github.com/.*)\.git}{http://$1};
		$data->{meta}{resources}{repository}{link} = $repo;
	}

	$data->{special_files} = \@special_files;

	foreach my $t ( @{ $data->{modules} }, @{ $data->{pods} } ) {
		$t->{path} =~ s{\\}{/}g;
	}

	return;
}

# unzip if needed or copy files if we were supplied with a directory structure (e.g. an svn checkout)
sub prepare_src {
	my ( $self, $d, $src_dir, $path ) = @_;

	my $full_path = File::Spec->catfile( $self->cpan, 'authors', 'id', $path );

	chdir $src_dir;
	my $distv_dir = File::Spec->catdir( $src_dir, $d->{distvname} );
	if ( not -e $distv_dir ) {
		my $unzip = $self->unzip( $path, $full_path, $d->{distvname} );
		return if not $unzip;
	}

	if ( not -e $d->{distvname} ) {
		WARN("No directory for '$d->{distvname}'");

		#$counter{no_directory}++;
		db->unzip_error( $path, 'no_directory', $d->{distvname} );
		return;
	}
	return 1;
}

# starting from current directory
sub generate_html_from_pod {
	my ( $self, $dir, $d ) = @_;

	my %ret;
	$ret{modules} = $self->_generate_html( $dir, '.pm',  'lib', $d );
	$ret{pods}    = $self->_generate_html( $dir, '.pod', 'lib', $d );

	return \%ret;
}

sub generate_syn {
	my ( $self, $dir, $files ) = @_;

	return if not $self->syn;

	foreach my $file (@$files) {
		my $outfile = File::Spec->catfile( $dir, $file->{path} );
		mkpath dirname $outfile;
		my $html;
		eval {
			my $ppi = CPAN::Digger::PPI->new( infile => $file->{path} );
			$html = $ppi->get_syntax;
		};
		if ($@) {
			ERROR("Exception while generating syn in PPI for $file->{path}  $@");
			next;
		}

		LOG("Save syn in $outfile");

		#my %data = (
		#filename => $opt{infile},
		#	code => $html,
		#);
		#my $tt = $self->get_tt;
		#$tt->process('syntax.tt', \%data, $outfile) or die $tt->error;
		open my $out, '>', $outfile;
		print $out qq{<div class="code">$html</div>};

	}

	return;
}

sub generate_outline {
	my ( $self, $dir, $files ) = @_;

	return if not $self->outline;

	my $pc = $self->critic ? Perl::Critic->new( -profile => $self->critic ) : undef;

	my @all_outlines;
	my %all_versions;
	my $all_version_markers = '';
	my %all_violations;
	foreach my $file (@$files) {

		my $min_perl;
		my $version_markers;
		my $outline;
		my @violations;
		eval {
			my $ppi = CPAN::Digger::PPI->new( infile => $file->{path} );

			$outline = PPIx::EditorTools::Outline->new->find( ppi => $ppi->get_ppi );

			( $min_perl, $version_markers ) = $ppi->min_perl;

			if ( $self->critic ) {
				@violations = $pc->critique( $ppi->get_ppi );
			}
		};
		if ($@) {
			ERROR("Exception in PPI while generating outline for $file->{path} $@");
			next;
		}

		my $outfile = File::Spec->catfile( $dir, "$file->{path}.json" );

		#my $vm_file = File::Spec->catfile($dir, "$file->{path}.vm.txt");
		#my $pc_file = File::Spec->catfile($dir, "$file->{path}.pc.txt");
		mkpath dirname $outfile;

		LOG( "Save outline in $outfile " . Dumper $outline);
		{
			open my $out, '>', $outfile;
			print $out to_json( $outline, { pretty => 1 } );
		}
		push @all_outlines, @$outline;

		my $module = $file->{path};
		$module =~ s{^lib/}{};
		$module =~ s{\.pm$}{};
		$module =~ s{/}{::}g;
		$all_versions{$module} = "$min_perl"; # forced stringification
		$all_version_markers .= "$module\n" . Dumper($version_markers) . "\n";

		if (@violations) {
			$all_violations{ $file->{path} } = \@violations;
		}
	}

	return ( \@all_outlines, \%all_versions, \%all_violations, $all_version_markers );
}

sub _generate_html {
	my ( $self, $dir, $ext, $path, $d ) = @_;

	my @files = eval {
		sort map { _untaint_path($_) }
			File::Find::Rule->file->name("*$ext")->extras( { untaint => 1 } )->relative->in($path);
	};

	# id/K/KA/KAWASAKI/WSST-0.1.1.tar.gz
	# directory (lib/WSST/Templates/perl/lib/WebService/) {company_name} is still tainted at /usr/share/perl/5.10/File/Find.pm line 869.
	if ($@) {
		WARN("Exception in File::Find::Rule: $@");
		return [];
	}
	my @data;
	my $tt     = $self->get_tt;
	my $author = uc $d->{author};

	my $dist = $d->{name};
	foreach my $file (@files) {
		my $module = substr( $file, 0, -1 * length($ext) );
		$module =~ s{/}{::}g;
		my $infile = File::Spec->catdir( $path, $file );
		my $outfile = File::Spec->catfile( $dir, $infile );
		mkpath dirname $outfile;

		my %info = (
			path => $infile,
			name => $module,
		);
		if ( $self->pod ) {
			LOG("POD: $infile -> $outfile");
			my $pod = CPAN::Digger::Pod->new();

			#$pod->batch_mode(1);
			# description?
			# keywords?
			my ( $header_top, $header_bottom, $footer );

			# We now only generate the "inside" of the pod and put it together
			# with the header and footer on-the fly.

			#$tt->process('incl/header_top.tt', {}, \$header_top) or die $tt->error;
			#$tt->process('incl/header_bottom.tt', {}, \$header_bottom) or die $tt->error;
			#$tt->process('incl/footer.tt', {}, \$footer) or die $tt->error;
			#$pod->html_header_before_title( $header_top );
			#$header_bottom .= qq((<a href="/src/$author/$d->{distvname}/$path/$file">source</a>));
			#$header_bottom .= qq((<a href="/syn/$dist/$path/$file">syn</a>));
			#$pod->html_header_after_title( $header_bottom );
			#$pod->html_footer( $footer );

			$pod->html_header_before_title('');
			$pod->html_header_after_title('');
			$pod->html_footer('');

			eval { $info{html} = $pod->process( $infile, $outfile ); };
			if ($@) {
				ERROR("Exception when processing pod '$infile' of $path to '$outfile'  $@");
				next;
			}
			$info{abstract} = delete $pod->{__abstract};
		}
		push @data, \%info;
	}
	return \@data;
}


sub generate_central_files {
	my $self = shift;

	# copy static files from public/ to --outdir
	my $outdir = _untaint_path( $self->output );

	#	mkpath $outdir;

	rcopy( File::ShareDir::dist_dir('CPAN-Digger'), $outdir );

	return;
}


sub unzip {
	my ( $self, $path, $full_path, $distvname ) = @_;

	if ( $full_path !~ m/\.(tar\.bz2|tar\.gz|tgz|zip)$/ ) {
		WARN("Does not know how to unzip $full_path");
		db->unzip_error( $path, 'invalid_extension', '' );
		return;
	}

	LOG("Unzipping '$full_path'");
	my $archive;
	eval {
		local $SIG{__WARN__} = sub { die shift };
		$archive = Archive::Any->new($full_path);
		die 'Could not unzip' if not $archive;
	};
	if ($@) {
		WARN("Exception in unzip: $@");
		db->unzip_error( $path, 'exception', $@ );
		return;
	}

	my $is_naughty;
	eval { $is_naughty = $archive->is_naughty; };

	# TODO!

	if ($is_naughty) {
		WARN("Archive is naughty");
		db->unzip_error( $path, 'naughty_archive', '' );
		return;
	}
	my $dir = $distvname;
	eval {
		if ( $archive->is_impolite )
		{
			mkdir $dir;
			$archive->extract($dir);
		} else {
			$archive->extract();
		}
	};
	if ($@) {
		WARN("Exception in unzip extract: $@");
		db->unzip_error( $path, 'exception', $@ );
		return;
	}

	# my $cwd = eval { _untaint_path(cwd()) };
	# if ($@) {
	# WARN("Could not untaint cwd: '" . cwd() . "'  $@");
	# return;
	# }
	# my $temp = tempdir( CLEANUP => 1 );
	# chdir $temp;
	# my ($out, $err) = eval { capture { system($cmd) } };
	# if ($@) {
	# die "$cmd $@";
	# }
	# if ($err) {
	# WARN("Command ($cmd) failed: $err");
	# chdir $cwd;
	# return;
	# }

	# TODO check if this was really successful?
	# TODO check what were the permission bits
	_chmod('.');

	opendir my ($dh), '.';
	my @content = eval {
		map { _untaint_path($_) } grep { $_ ne '.' and $_ ne '..' } readdir $dh;
	};
	if ($@) {
		WARN("Could not untaint content of directory: $@");

		#chdir $cwd;
		db->unzip_error( $path, 'tainted_directory', $@ );
		return;
	}

	#print "CON: @content\n";
	# if (@content == 1 and $content[0] eq $d->distvname) {
	# # using external mv as File::Copy::move cannot move directory...
	# my $cmd_move = "mv " . $d->distvname . " $cwd";
	# #LOG("Moving " . $d->distvname . " to $cwd");
	# LOG($cmd_move);
	# #move $d->distvname, File::Spec->catdir( $cwd, $d->distvname );
	# system($cmd_move);
	# # TODO: some files open with only read permissions on the main directory.
	# # this needs to be reported and I need to correct it on the local unzip setting
	# # xw on the directories and w on the files
	# #chdir $cwd;
	# return 1;
	# } else {
	# my $target_dir = eval { _untaint_path(File::Spec->catdir( $cwd, $d->distvname )) };
	# if ($@) {
	# WARN("Could not untaint target_directory: $@");
	# chdir $cwd;
	# return;
	# }
	# LOG("Need to create $target_dir");
	# mkdir $target_dir;
	# foreach my $thing (@content) {
	# system "mv $thing $target_dir";
	# }
	# chdir $cwd;
	# return 2;
	# }

	return 1;
}

sub _chmod {
	my $dir = shift;
	opendir my ($dh), $dir;
	my @content = eval {
		map { _untaint_path($_) } grep { $_ ne '.' and $_ ne '..' } readdir $dh;
	};
	if ($@) {
		WARN("Could not untaint: $@");
	}
	foreach my $thing (@content) {
		my $path = File::Spec->catfile( $dir, $thing );
		if ( -l $path ) {
			WARN("Symlink found '$path'");
			unlink $path;
		} elsif ( -d $path ) {
			chmod 0755, $path;
			_chmod($path);
		} elsif ( -f $path ) {
			chmod 0644, $path;
		} else {
			WARN("Unknown thing '$path'");
		}
	}
	return;
}

sub _untaint_path {
	my $p = shift;
	if ( $p =~ m{^([\w/:\\.-]+)$}x ) {
		$p = $1;
	} else {
		Carp::confess("Untaint failed for '$p'\n");
	}
	if ( index( $p, '..' ) > -1 ) {
		Carp::confess("Found .. in '$p'\n");
	}
	return $p;
}

sub collect_distributions {
	my ($self) = @_;

	LOG('collecting list of distributions');

	return if not $self->cpan;

	db->dbh->begin_work;

	my $files = File::Find::Rule->file()->relative

		#   ->name( '*.tar.gz' )
		->start( $self->cpan . '/authors/id' );

	while ( my $file = $files->match ) {
		next if $file =~ m{.meta$};
		next if $file =~ m{.readme$};
		next if $file =~ m{.pl$};
		next if $file =~ m{.pm$};
		next if $file =~ m{.txt$};
		next if $file =~ m{.png$};
		next if $file =~ m{.html$};
		next if $file =~ m{CHECKSUMS$};
		next if $file =~ m{/\w+$};

		# limit processing when profiling
		#$main::count++;
		#last if $main::count > 200;

		# Sample files:
		# F/FA/FAKE1/My-Package-1.02.tar.gz
		# Z/ZI/ZIGOROU/Module-Install-TestVars-0.01_02.tar.gz
		# G/GR/GREENBEAN/Asterisk-AMI-v0.2.0.tar.gz
		# Z/ZA/ZAG/Objects-Collection-029targz/Objects-Collection-0.29.tar.gz
		my $PREFIX           = qr{\w/\w\w/(\w+)/};
		my $SUBDIRS          = qr{(?:[\w/-]+/)};
		my $PACKAGE          = qr{([\w-]*?)};
		my $VERSION_NO       = qr{[\d._]+};
		my $CRAZY_VERSION_NO = qr {[\w.]+};
		my $EXTENSION        = qr{(?:\.tar\.gz|\.tgz|\.zip|\.tar\.bz2)};
		my $full_path        = $self->cpan . '/authors/id/' . $file;
		if ($file =~ m{^$PREFIX           # P/PA/PAUSEID
			   $SUBDIRS?          # optional garbage
			   $PACKAGE
			   -v?($VERSION_NO)      # version
			   $EXTENSION
			   $}x
			)
		{

			#print "$1  - $2 - $3\n";
			my @args = ( $1, $2, $3, $file, ( stat $full_path )[9], time );
			LOG("insert_distro @args");
			db->insert_distro(@args);

			# K/KR/KRAKEN/Net-Telnet-Cisco-IOS-0.4beta.tar.gz
		} elsif (
			$file =~ m{^$PREFIX           # P/PA/PAUSEID
			   $SUBDIRS?          # optional garbage
			   $PACKAGE
			   -v?($CRAZY_VERSION_NO)      # version
			   $EXTENSION
			   $}x
			)
		{
			my @args = ( $1, $2, $3, $file, ( stat $full_path )[9], time );
			LOG("insert_distro @args");
			db->insert_distro(@args);
		} else {
			WARN("could not parse filename '$file'");
		}
	}

	db->dbh->commit;

	LOG('done collecting distributions');

	return;
}

sub update_from_whois {
	my ($self) = @_;

	LOG('start whois');
	my $file = $self->cpan . '/authors/00whois.xml';
	if ( not -e $file ) {
		die "Could not find whois file $file";

		# TODO minim cpan does not mirror this file
		# either ask RJBS to include it, mirror ourself or use the
		# other file (01mailrc.txt.gz) I think
		# create ~/.minicpanrc with the following line in it:
		#  also_mirror: authors/00whois.xml
	}

	db->dbh->begin_work;

	my $whois = Parse::CPAN::Whois->new($file);
	foreach my $who ( $whois->authors ) {
		my $pauseid = $who->pauseid;
		my $have    = db->get_author($pauseid);

		#print Dumper $have;
		my %new_data;
		my $changed;
		foreach my $field (qw(email name asciiname homepage)) {
			$new_data{$field} = $who->$field;
			if ($have) {
				no warnings;
				$changed = 1 if $new_data{$field} ne $have->{$field};
			}
		}
		my $homedir =
			sprintf( '%s/authors/id/%s/%s/%s', $self->cpan, substr( $pauseid, 0, 1 ), substr( $pauseid, 0, 2 ),
			$pauseid );
		$new_data{homedir} = -d $homedir ? 1 : 0;

		# has author.json ?
		my %author_profile;
		my ($author_file) = reverse sort glob "$homedir/author-*.json";
		my $author_json;
		if ($author_file) {
			eval { $author_json = from_json slurp($author_file) };
			if ($@) {
				ERROR("Failed to load '$author_file': $@");
			} else {
				$new_data{author_json} = basename $author_file;
			}
		}

		if ( not $have ) {
			LOG( "add_author $pauseid " . Dumper \%new_data );
			db->add_author( \%new_data, $pauseid );
		} elsif ($changed) {
			LOG( "update_author $pauseid " . Dumper \%new_data );
			db->update_author( \%new_data, $pauseid );
		}
		if ($author_json) {
			LOG( "updating author_json for $pauseid from $author_file by " . Dumper $author_json);
			db->update_author_json( $author_json, $pauseid );
		}
	}

	db->dbh->commit;

	LOG('whois finished');

	return;
}


1;
