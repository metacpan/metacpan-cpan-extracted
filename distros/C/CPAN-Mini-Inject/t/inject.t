use strict;
use warnings;

use Test::More;

use File::Path qw(make_path);
use File::Copy;
use File::Temp ();
use File::Basename;
use File::Spec::Functions qw(catfile);
use Compress::Zlib;

use lib qw(t/lib);
use Local::utils;

my $class = 'CPAN::Mini::Inject';

my $temp_dir = File::Temp::tempdir(CLEANUP=>1);

=begin comment

C<remote> is the URL for the repo from which we'll download latest versions

C<local> is our MiniCPAN

C<repository> is the dir where we will keep the modules to inject

=end comment

=cut

subtest 'sanity' => sub {
	use_ok $class or BAIL_OUT( "Could not load $class: $@" );
	can_ok $class, 'new';
	isa_ok $class->new, $class;
	};

subtest 'setup directories in temp dir' => sub {
	my @dirs = (
		[ qw(modules) ],
		[ qw(authors) ],
		[ qw(injects) ],
		);

	foreach my $dir ( @dirs ) {
		my $path = catfile $temp_dir, @$dir;
		make_path( $path );
		ok -d $path, "Path for <@$dir> exists";
		}
	};

my $t_local = catfile qw(t local);
subtest 'check local dir' => sub {
	ok -d $t_local, 'local directory exists';
	};

subtest 'copy initial files' => sub {
	my $modules_base = catfile $temp_dir, 'modules';
	ok -d $modules_base, 'modules dir exists';

	my $authors_base = catfile $temp_dir, 'authors';
	ok -d $authors_base, 'authors dir exists';

	subtest 'packages' => sub {
		my $file = '02packages.details.txt.gz';
		my $destination = catfile $modules_base, $file;
		my $rc = copy(
		  catfile( $t_local, 'CPAN', 'modules', "$file.original" ),
		  $destination
		);
		ok $rc, 'File::Copy worked';
		ok -e $destination, 'Copied packages file to temp_dir';
		ok chmod(0666, $destination), 'chmod packages to 0666';
		};

	subtest 'mailrc' => sub {
		my $file = '01mailrc.txt.gz';
		my $destination   = catfile $authors_base, $file;
		my $rc = copy(
		  catfile( $t_local, "$file.original" ),
		  $destination
		);
		ok $rc, 'File::Copy worked';
		ok -e $destination, 'Copied mailrc file to temp_dir';
		ok chmod(0666, $destination), 'chmod mailrc to 0666';
		};
	};

sub get_module_details {
	my( $dist_sources ) = @_;
	my @modules = (
		{
		module   => 'CPAN::Mini::Inject',
		authorid => 'SSORICHE',
		version  => '0.01',
		file     => catfile( $dist_sources, 'CPAN-Mini-Inject-0.01.tar.gz' ),
		},
		{
		module   => 'CPAN::Mini::Inject',
		authorid => 'SSORICHE',
		version  => '0.02',
		file     => catfile( $dist_sources, 'CPAN-Mini-Inject-0.01.tar.gz' ),
		},
		{
		module   => 'CPAN::Mini',
		authorid => 'RJBS',
		version  => '0.17',
		file     => catfile( $dist_sources, 'CPAN-Mini-0.17.tar.gz' ),
		},
		);
	}

subtest 'inject the modules' => sub {
	my $dist_sources = catfile $t_local, 'mymodules';
	ok -d $dist_sources, 'Dist sources directory exists';
	my @modules = get_module_details( $dist_sources );

	my $tmp_config_file;
	subtest 'make config' => sub {
		$tmp_config_file = write_config(
			local      => $temp_dir,
			repository => catfile( $temp_dir, 'injects' ),
			);
		ok -e $tmp_config_file, 'configuration file exists';
		};

	my $mcpi = $class->new;
	isa_ok $mcpi, $class;

	$mcpi = $mcpi->loadcfg( $tmp_config_file )->parsecfg->readlist;

	foreach my $module ( @modules ) {
		ok -e $module->{file}, "module file <$module->{file}> exists";
		$mcpi = $mcpi->add( %$module );
		}

	subtest 'writelist' => sub {
		ok $mcpi->writelist, 'inject modules';
		};

	subtest 'inject' => sub {
		ok $mcpi->inject( $ENV{TEST_VERBOSE} // 0 ), 'copy modules';
		};

	subtest 'check the result' => sub {
		my $authors_dir = catfile $temp_dir, 'authors';
		ok -e $authors_dir, 'authors dir exists';

		foreach my $module ( @modules ) {
			subtest "check $module->{file}" => sub {
				my $author_stub = catfile(
					$authors_dir,
					'id',
					substr( $module->{authorid}, 0, 1 ),
					substr( $module->{authorid}, 0, 2 ),
					$module->{authorid}
					);
				ok -d $author_stub, "author directory $author_stub for $module->{authorid} exists";
				is( mode($author_stub), 0775, 'author dir mode is 775' ) if has_modes();

				my $module_basename = basename $module->{file};
				my $module_path = catfile $author_stub, $module_basename;
				ok -e $module_path, "$module_basename exists in local";
				is( mode($module_path), 0664, 'moduole filr is mode is 664' ) if has_modes();

				subtest 'CHECKSUMS' => sub {
					my $checksums_path = catfile $author_stub, 'CHECKSUMS';
					my $rc = ok -e $checksums_path, "CHECKSUMS file for $module->{authorid} exists";
					is( mode($checksums_path), 0664, 'checksum file mode is 664' ) if has_modes();

					if( $rc ) {
						my $rc = open my $chk, '<', $checksums_path;
						my $checksum_text = join "", <$chk>;
						close $chk;
						unlike $checksum_text, qr{\Q$authors_dir\E/id}, "root path isn't leaked to checksums";
						}
					else {
						fail "Can't check CHECKSUMS since it doesn't exist";
						}
					};
				};
			}
		};
	};

subtest 'packages updated' => sub {
	my @goodfile = <DATA>;
	my $packages = catfile $temp_dir, 'modules', '02packages.details.txt.gz';
	ok -e $packages, 'packages files exists';

	ok( my $gzread = gzopen( $packages, 'rb' ), 'opened packages for reading' );

	my @packages;
	my $line;
	while ( $gzread->gzreadline( $line ) ) {
	  if ( $line =~ /^Written-By:/ ) {
		push( @packages, "Written-By:\n" );
		next;
	  }
	  if ( $line =~ /^Last-Updated:/ ) {
		push( @packages, "Last-Updated:\n" );
		next;
	  }
	  push( @packages, $line );
	}
	$gzread->gzclose;

	is_deeply( \@goodfile, \@packages, 'got expected packages file data' );
	};

subtest 'mailrc updated' => sub {
	my $mailrc = catfile $temp_dir, 'authors', '01mailrc.txt.gz';
	ok -e $mailrc, 'mailrc files exists';

	ok( my $gzauthread = gzopen( $mailrc, 'rb' ), 'opened mailrc for reading' );

	my %inject_authors = map { $_->{authorid} => 1 } get_module_details('');

	my $line;
	my %found_authors;
	while ( $gzauthread->gzreadline( $line ) ) {
		next unless $line =~ /\A alias \h+ ([A-Z]+)/x;
		$found_authors{$1}++;
		fail( "Found $1 $found_authors{$1} times" ) if $found_authors{$1} > 1;
		}
	$gzauthread->gzclose;

	foreach my $author ( keys %inject_authors ) {
		ok exists $found_authors{$author}, "Found $author in $mailrc";
		}
	};

done_testing();

__DATA__
File:         02packages.details.txt
URL:          http://www.perl.com/CPAN/modules/02packages.details.txt
Description:  Package names found in directory $CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:
Line-Count:   7
Last-Updated:

abbreviation                       0.02  M/MI/MIYAGAWA/abbreviation-0.02.tar.gz
Acme::Code::Police               2.1828  O/OV/OVID/Acme-Code-Police-2.1828.tar.gz
BFD                                0.31  R/RB/RBS/BFD-0.31.tar.gz
CPAN::Mini                         0.17  R/RJ/RJBS/CPAN-Mini-0.17.tar.gz
CPAN::Mini::Inject                 0.02  S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz
CPAN::Nox                          1.02  A/AN/ANDK/CPAN-1.76.tar.gz
CPANPLUS                          0.049  A/AU/AUTRIJUS/CPANPLUS-0.049.tar.gz
