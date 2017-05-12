package CPAN::Digger::WWW;

our $VERSION = '0.08';

use Dancer ':syntax';

use Data::Dumper qw(Dumper);
use Encode qw(decode);
use File::Basename qw(basename);
use File::Find::Rule;
use List::Util qw(max);
use POSIX ();
use Time::HiRes qw(time);
use YAML ();

use CPAN::Digger::DB;
use CPAN::Digger::Tools;

#set serializer => 'Mutable';

sub render_response {
	my ( $template, $data ) = @_;

	$data ||= {};
	$data->{elapsed_time} = int( 10_000 * ( time - vars->{start} ) ) / 10_000;
	$data->{digger_version} = $VERSION;
	my $content_type = request->content_type || params->{content_type} || '';
	if ( $content_type =~ /json/ ) {
		content_type 'text/plain';
		return to_json $data, { utf8 => 0 };
	} else {
		return template $template, $data;
	}
}

my $dbx;

sub db {
	if ( not $dbx ) {
		$dbx = CPAN::Digger::DB->new( dbfile => config->{digger}{dbfile} );
		$dbx->setup;
	}
	return $dbx;

}

hook before => sub {
	var start => time;

	return;
};

get '/' => sub {
	return render_response 'index', {};
};

# search.cpan.org keeps the users in ~pauseid
# This is a UNIXism so we have them under /id/pauseid
# but we want to make it comfortable to those who used to the way
# search.cpan.org does this
get '/~*' => sub {
	my ($path) = splat;
	redirect '/id/' . $path;
};

get '/id/:pauseid/' => sub {
	redirect '/id/' . params->{pauseid};
};

get '/id/:pauseid' => sub {
	my $pauseid = lc( params->{pauseid} || '' );

	# TODO show error if no pauseid received
	$pauseid =~ s/\W//g; # sanitise

	debug($pauseid);

	my $author = db->get_author( uc $pauseid );
	debug( Dumper $author);
	my $distributions = db->get_distros_of( uc $pauseid );
	my $last_upload = max( map { $_->{file_timestamp} } @$distributions );

	foreach my $d (@$distributions) {
		$d->{release}   = _date( delete $d->{file_timestamp} );
		$d->{distrover} = "$d->{name}-$d->{version}";
		$d->{filename}  = basename( $d->{path} );
	}
	my %data = (
		name => decode( 'utf8', $author->{name} || $author->{asciiname} || '' ),
		last_upload => ( $last_upload ? _date($last_upload) : 'NA' ),
		pauseid     => uc($pauseid),
		lcpauseid   => lc($pauseid),
		email       => $author->{email},
		link_email => ( $author->{email} and $author->{email} ne 'CENSORED' ? 1 : 0 ),
		homepage   => $author->{homepage},
		homedir    => $author->{homedir},
		backpan       => uc( join( "/", substr( $pauseid, 0, 1 ), substr( $pauseid, 0, 2 ), $pauseid ) ),
		distributions => $distributions,
	);
	my $homedir = config->{digger}{cpan} . "/authors/id/$data{backpan}";
	my ($author_file) = reverse sort glob "$homedir/author-*.json";
	if ($author_file) {
		$data{author_json}{file} = basename $author_file;
		eval { $data{author_json}{data} = from_json slurp($author_file) };
	}

	return render_response 'author', \%data;
};


get '/grep' => sub {
	my $name = params->{dist};
	my $str  = params->{str};

	$name =~ s/[^\w-]//g; # sanitise
	$str  =~ s/[^\w-]//g; # sanitise

	my $regex = qr/$str/;

	# TODO replace this with ack integration???

	my $d         = db->get_distro_latest($name);
	my $distvname = "$name-$d->{version}";
	my $full_path = path config->{appdir}, '..', 'digger', "/src/$d->{author}/$distvname/";

	# TODO for now we only search the lib/   subdir
	# process all the files
	my @files = File::Find::Rule->file->name('*.pm')->relative->in("$full_path/lib");

	my %data;
	foreach my $f (@files) {
		open my $fh, '<', "$full_path/lib/$f" or next;
		my $cnt = 0;
		while ( my $line = <$fh> ) {
			$cnt++;
			if ( $line =~ $regex ) {
				push @{ $data{"lib/$f"}{match} },
					{
					line => _escape($line),
					cnt  => $cnt,
					};
			}
		}
		if ( $data{"lib/$f"} ) {
			$data{"lib/$f"}{link} = substr( $f, 0, -3 );
			$data{"lib/$f"}{link} =~ s{/}{::}g;
		}
	}

	return render_response 'grep',
		{
		matches => \%data,
		dist    => $name,
		};
};


get '/dist/:name/' => sub {
	redirect '/dist/' . params->{name};
};

get '/dist/:name' => sub {
	my $name = params->{name} || '';

	# TODO show error if no name received
	$name =~ s/[^\w-]//g; # sanitise

	debug($name);

	my $d = db->get_distro_latest($name);
	if ( not $d ) {
		return render_response 'error',
			{
			no_such_distribution => 1,
			name                 => $name,
			};
	}

	my $details = db->get_distro_details_by_id( $d->{id} );
	$details ||= {}; #TODO shall we report if not found?
	                 #debug(Dumper $d);
	                 #debug(Dumper $details);

	my $author = db->get_author( uc $d->{author} );
	$author ||= { name => '' }; #TODO shall we report if not found?

	#debug($d->{file_timestamp});
	#debug(_date($d->{file_timestamp}));

	my $distvname = "$name-$d->{version}";

	my %meta_data;
	$meta_data{$_} = $details->{"meta_$_"} for qw(abstract version license);

	# Temporary solution ??? (or maybe not?) reading the META.yml file
	# on the fly
	my $full_path = path config->{appdir}, '..', 'digger', "/src/$d->{author}/$distvname/META.yml";
	if ( defined $full_path and -e $full_path ) {
		my $yaml;
		eval { $yaml = YAML::LoadFile($full_path) };
		if ($yaml) {
			if ( $yaml->{requires} ) {
				$meta_data{requires} = $yaml->{requires};
			}
		}
	}

	# TODO: also process META.json where available

	my %data = (
		name      => $name,
		pauseid   => $d->{author},
		released  => _date( $d->{file_timestamp} ),
		distvname => $distvname,
		,
		author => {
			name => decode( 'utf8', $author->{name} ),
		},
		meta_data => \%meta_data,
	);
	$data{$_} = $d->{$_}       for qw(version path);
	$data{$_} = $details->{$_} for qw(has_t test_file has_meta_yml has_meta_json examples min_perl);
	if ( $details->{special_files} ) {
		$data{special_files} = [ split /,/, $details->{special_files} ];
	}
	if ( $details->{pods} ) {
		$data{modules} = from_json( $details->{pods} );
	}

	return render_response 'dist', \%data;
};

foreach my $page (qw(news faq)) {
	get "/$page" => sub {
		return render_response $page, {};
	};
	get "/$page/" => sub {
		redirect "/$page";
	};
}

get '/stats' => sub {

	my %data = (
		unzip_errors                  => db->count_unzip_errors,
		total_number_of_distributions => db->count_distros,
		distinct_distributions        => db->count_distinct_distros,
		has_meta_json                 => db->count_meta_json,
		has_meta_yaml                 => db->count_meta_yaml,
		has_no_meta                   => db->count_no_meta,
		has_test_file                 => db->count_test_file,
		has_t_dir                     => db->count_t_dir,
		has_xt_dir                    => db->count_xt_dir,
		has_no_tests                  => db->count_no_tests,

		number_of_authors     => db->count_authors,
		number_of_author_json => db->count_author_json,

		number_of_modules => db->count_modules,

		number_of_files      => db->count_files,
		number_of_policies   => db->count_pc_policies,
		number_of_violations => db->count_violations,
	);

	return render_response 'stats', \%data;
};

# get '/licenses' => sub {
# my $data_file = path config->{public}, 'data', 'licenses.json';
# my $json = eval {from_json slurp($data_file)};
# template 'licenses', {
# licenses => $json,
# };
# };

get '/query' => sub {
	my $term = params->{query} || '';
	my $what = params->{what}  || '';

	if ( $what !~ /^(distribution|author|all)$/ ) {
		return render_response 'error',
			{
			invalid_search => 1,
			what           => $what,
			};
	}

	$term =~ s/[^\w:.*+?-]//g; # sanitize for now
	                           #my $data = { 'abc' => $term };


	my $data;

	if ( $what eq 'all' ) {
		my $found;

		# check if there is an exact match in the modules
		my $module = db->get_module_by_name($term);
		if ($module) {
			my $distro = db->get_distro_by_id( $module->{distro} );
			if ($distro) {
				$term =~ s{::}{/}g;
				foreach my $ext (qw(pm pod)) {
					my $path = "/dist/$distro->{name}/lib/$term.$ext";
					my $full_path = path config->{appdir}, '..', 'digger', $path;
					return redirect $path if -e $full_path;
				}
			}
		}

		# fall back to
		$what = 'distribution';

		# later check if there is an exact match in the distros
		# and add other improvements
	}


	if ( $what eq 'distribution' ) {
		$data = db->get_distros_latest_version($term);
		$_->{show_distribution} = 1 for @$data;
	}
	if ( $what eq 'author' ) {
		$data = db->get_authors($term);
		$_->{show_author} = 1 for @$data;
		foreach my $d (@$data) {
			$d->{name} = decode( 'utf8', $d->{name} );
		}
	}

	return render_response 'query', { data => $data };
};

get '/m/:module' => sub {
	my $name = params->{module} || '';
	$name =~ s/[^\w:.*+?-]//g; # sanitize for now

	my $module = db->get_module_by_name($name);
	if ( not $module ) {
		return render_response 'error',
			{
			no_such_module => 1,
			module         => $name,
			};
	}

	my $distro = db->get_distro_by_id( $module->{distro} );
	return "Wow, could not find corresponding distribution" if not $distro;

	$name =~ s{::}{/}g;
	foreach my $ext (qw(pm pod)) {
		my $path = "/dist/$distro->{name}/lib/$name.$ext";
		my $full_path = path config->{appdir}, '..', 'digger', $path;
		return redirect $path if -e $full_path;
	}

	return render_response 'error',
		{
		no_pod_found => 1,
		module       => $name,
		};


	#my $distro_details = db->get_distro_details_by_id($distro->{id});
	#return to_json {module => $module, distro => $distro, details => $distro_details};
	#return $distro_details->{pods};

	# # TODO: maybe in case of no hit, run the query with regex and find
	# # all the modules (or packages?) that have this string in their name

	# TODO what if we received several results?
	# Should we show a list of links?
};


# this part is only needed in the stand alone environment
# if used under Apache, then Apache should be configured
# to handle these static files
get qr{/(syn|src|dist)(/.*)?} => sub {

	# TODO this gives a warning in Dancer::Router if we ask for dist only as the
	# capture in the () is an undef
	#my ($path) = splat;
	#$path ||= '/';
	#$path = "/dist$path";

	my $path = request->path;

	# TODO: how can I add a configuration option to config.yml
	# to point to a directory relative to the appdir ?
	#return config->{appdir};
	my $full_path = path config->{appdir}, '..', 'digger', $path;
	if ( not defined $full_path ) {
		return render_response 'error',
			{
			cannot_handle => 1,
			};
	}


	if ( -d $full_path ) {
		if ( $path !~ m{/$} ) {
			return redirect request->path . '/';
		}
		if ( -e path( $full_path, 'index.html' ) ) {
			$full_path = path( $full_path, 'index.html' );
		} else {
			if ( opendir my $dh, $full_path ) {
				my ( @dirs, @files );
				while ( my $thing = readdir $dh ) {
					next if $thing eq '.' or $thing eq '..';
					if ( -d path $full_path, $thing ) {
						push @dirs, $thing;
					} else {
						push @files, $thing;
					}
				}
				return render_response 'directory',
					{
					dirs  => \@dirs,
					files => \@files,
					};
			} else {
				return render_response 'error',
					{
					no_directory_listing => 1,
					};

			}

			#return "directory listing $full_path";
		}
	}
	if ( -f $full_path ) {

		#        print STDERR "Serving '$full_path'\n";
		if ( -s $full_path ) {
			if ( $path =~ m{/src} or $path =~ m{\.pm\.json$} ) { # TODO stop hard coding here!
				content_type 'text/plain';
				return slurp($full_path);
			} else {

				# get the name of the distro
				# using that get the author, the latest version
				my %data = (
					html => scalar slurp($full_path),
				);

				my $dist_name;
				my $sub_path;
				if ( $path =~ m{^/dist/([^/]+)/(.*)} ) {
					$dist_name = $1;
					$sub_path  = $2;
					( $data{syn} = $path ) =~ s{^/dist}{/syn};
				}
				if ( $path =~ m{^/syn/([^/]+)/(.*)} ) {
					$dist_name = $1;
					$sub_path  = $2;
					( $data{pod} = $path ) =~ s{^/syn}{/dist};
					$data{outline} = _get_outline( path config->{appdir}, '..', 'digger', "$data{pod}.json" );
				}

				#if ($path =~ m{^/src
				if ($dist_name) {
					my $d = db->get_distro_latest($dist_name);

					#my $details = db->get_distro_details_by_id($d->{id});
					$data{src}   = "/src/$d->{author}/$dist_name-$d->{version}/$sub_path";
					$data{dist}  = $dist_name;
					$data{title} = $dist_name;
				}

				return render_response 'file', \%data;
			}

		} else {
			return "This file was empty";
		}
	}

	return render_response 'error',
		{
		cannot_handle => 1,
		};
};

get '/violations' => sub {
	return render_response 'violations', { violations => db->get_top_pc_policies };
};

sub _get_outline {
	my ($path) = @_;
	if ( -e $path ) {
		my $data;
		eval { $data = from_json slurp($path) };
		return $data if $data and not $@;
	}
	return;
}

sub _date {
	return POSIX::strftime( "%Y %b %d", gmtime shift );
}

sub _escape {
	my $str = shift;
	$str =~ s{<}{&lt;}g;
	$str =~ s{>}{&gt;}g;
	return $str;
}

true;

=head1 NAME

CPAN::Digger::WWW - Dancer based web interface to L<CPAN::Digger>

=head1 COPYRIGHT

Copyright 2010 Gabor Szabo L<gabor@szabgab.com>


=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2010 Gabor Szabo http://szabgab.com/
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

