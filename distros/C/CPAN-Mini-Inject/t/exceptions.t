use strict;
use warnings;

use Test::More;

BEGIN {
	eval "use Test::Exception";
	plan skip_all => "Test::Exception required for exceptions.t" if $@;
	}

use File::Spec::Functions qw(catfile);
use File::Path qw(make_path);
use File::Temp ();
use Socket qw(getaddrinfo);

use lib 't/lib';
use Local::utils;

my $class = 'CPAN::Mini::Inject';

$SIG{'INT'} = sub { print "\nCleaning up before exiting\n"; exit 1 };
my $temp_dir = File::Temp::tempdir(CLEANUP=>1);

subtest 'sanity' => sub {
	use_ok $class or BAIL_OUT( "Could not load $class: $@" );
	can_ok $class, 'new';
	isa_ok $class->new, $class;
	};

subtest 'config problems' => sub {
	subtest 'no config' => sub {
		delete local $ENV{HOME};
		delete local $ENV{MCPANI_CONFIG};

		SKIP: {
			skip 'Global config file exists. Cannot test no config situation.', 1 if global_config_exists();
			my $mcpi = $class->new;
			isa_ok $mcpi, $class;
			dies_ok { $mcpi->loadcfg } 'No config file';
			}
		};

	subtest 'bad config' => sub {
		my $tmp_config_file = catfile $temp_dir, 'bad_config';
		subtest 'create bad config file' => sub {
			my $fh;
			if( open $fh, '>', $tmp_config_file ) {
				print {$fh} <<'HERE';
# This file is missing a local setting.
remote : http://www.cpan.org
repository: t/local/MYCPAN
passive: yes
This line will be ignored
HERE
				ok close($fh), "created bad config file";
				}
			else {
				fail("could not create config with missing local setting");
				}
			};

		ok -e $tmp_config_file, 'bad config with missing local setting file exists';

		my $mcpi = $class->new;
		isa_ok $mcpi, $class;
		dies_ok { $mcpi->parsecfg( $tmp_config_file ); } 'Missing local setting blows up';
		};

	subtest 'unreadable' => sub {
		SKIP: {
			skip 'User is superuser and can always read', 1 if $< == 0;
			skip 'User is generally superuser under cygwin and can read', 1 if $^O eq 'cygwin';

			my $repo_dir = catfile $temp_dir, 'injects';
			ok make_path($repo_dir), "make_path for injects/ succeeded";

			my $tmp_config_file = catfile $temp_dir, 'bad_config';
			my $fh;
			if(open $fh, '>', $tmp_config_file) {
				print {$fh} "Hello";
				close $fh;
				chmod 0111, $tmp_config_file;
				is( mode($tmp_config_file), 0111, 'mode for config is 0111' );
				ok -e $tmp_config_file, 'config file exists';
				ok ! -r $tmp_config_file, 'config file is not readable';
				}
			else {
				fail("Could not create an unreadable file");
				}

			my $mcpi = $class->new;
			isa_ok $mcpi, $class;

			dies_ok { $mcpi->parsecfg($tmp_config_file) } 'unreadable file';
			like $@, qr/Could not read file/, 'exception has expected message';
			chmod 0644, $tmp_config_file;
			}
		};

	subtest 'no repo config' => sub {
		my $tmp_config_file = catfile $temp_dir, 'bad_config';
		subtest 'create no repo config file' => sub {
			my $fh;
			if(open $fh, '>', $tmp_config_file) {
				print {$fh} "local: t/local/CPAN\nremote: http://www.cpan.org\n";
				close $fh;
				ok -e $tmp_config_file, 'config file exists';
				ok -r $tmp_config_file, 'config file is readable';
				}
			else {
				fail("Could not create no repo config file");
				}
			};

		my $mcpi = $class->new;
		isa_ok $mcpi, $class;

		lives_ok { $mcpi->parsecfg($tmp_config_file) } 'no repo config file parses';
		dies_ok {
			$mcpi->add(
			  module   => 'CPAN::Mini::Inject',
			  authorid => 'SSORICHE',
			  version  => '0.01',
			  file     => 'test-0.01.tar.gz'
			);
			} 'Missing config repository';
		like $@, qr/No repository configured/, 'exception has expected message';
		};

	subtest 'read-only repo' => sub {
		SKIP: {
			skip 'this system does not do file modes', 3 unless has_modes();
			my $tmp_config_file = catfile $temp_dir, 'bad_config';

			my $repo_dir = catfile $temp_dir, 'read-only-injects';
			subtest 'create read-only repo dir' => sub {
				ok make_path($repo_dir), 'created repo dir';
				chmod 0555, $repo_dir;
				is mode($repo_dir), 0555, 'repo dir has mode 444';
				ok ! -w $repo_dir, 'repo dir is not writable';
				};

			subtest 'create read-only repo config file' => sub {
				my $fh;
				if(open $fh, '>', $tmp_config_file) {
				print {$fh} <<"HERE";
local: $temp_dir
remote: http://www.cpan.org
repository: $repo_dir
HERE
					close $fh;
					ok -e $tmp_config_file, 'config file exists';
					ok -r $tmp_config_file, 'config file is readable';
					}
				else {
					fail("Could not create read-only repo config file");
					}
				};

			subtest 'try to add to read-only repo' => sub {
				my $mcpi = $class->new;
				isa_ok $mcpi, $class;

				lives_ok { $mcpi->parsecfg($tmp_config_file) } 'read-only repo config file parses';
				dies_ok {
					$mcpi->add(
					  module   => 'CPAN::Mini::Inject',
					  authorid => 'SSORICHE',
					  version  => '0.01',
					  file     => 'test-0.01.tar.gz'
					);
				  }
				  'read-only repository';
				like $@, qr/Can not write to repository/, 'exception has expected message';
				};

			chmod 755, $repo_dir;
			};
		}
	};

subtest 'add exceptions' => sub {
	my $repo_dir = catfile $temp_dir, 'injects';
	subtest 'create repo dir' => sub {
		ok make_path($repo_dir), 'created repo dir' unless -d $repo_dir;
		chmod 0755, $repo_dir;
		is mode($repo_dir), 0755, 'repo dir has mode 444' if has_modes();
		ok -r $repo_dir, 'repo dir is readable';
		ok -w $repo_dir, 'repo dir is writable';
		};

	my $tmp_config_file = catfile $temp_dir, 'good_config';
	subtest 'create config file' => sub {
		my $fh;
		if(open $fh, '>', $tmp_config_file) {
			print {$fh} <<"HERE";
local: $temp_dir
remote : http://localhost:11027
repository: $repo_dir
dirmode: 0775
passive: yes
HERE
			close $fh;
			ok -e $tmp_config_file, 'config file exists';
			ok -r $tmp_config_file, 'config file is readable';
			}
		else {
			fail("Could not create config file");
			}
		};

	my $mcpi = $class->new;
	isa_ok $mcpi, $class;

	lives_ok { $mcpi->parsecfg( $tmp_config_file ) } 'parsecfg works';

	subtest 'missing file param' => sub {
		dies_ok {
			$mcpi->add(
				module   => 'CPAN::Mini::Inject',
				authorid => 'SSORICHE',
				version  => '0.01'
				);
			} 'Missing add param';
		like $@, qr/Required option not specified: file/,  'exception has expected message';
		};

	subtest 'module file is missing' => sub {
		dies_ok {
			$mcpi->add(
				module   => 'CPAN::Mini::Inject',
				authorid => 'SSORICHE',
				version  => '0.01',
				file     => 'blahblah'
				);
		} 'Module file not readable';
		like $@, qr/Can not read module file: blahblah/,  'exception has expected message';
		};

	subtest 'discoverable' => sub {
		lives_ok {
			$mcpi->add(
				authorid => 'RWSTAUNER',
				file     => 't/local/mymodules/Dist-Metadata-Test-MetaFile-Only.tar.gz'
				);
			} 'Ok without module/version when discoverable';
		};

	subtest 'not discoverable' => sub {
		lives_ok {
			$mcpi->add(
				module   => 'Who::Cares',
				version  => '1',
				authorid => 'RWSTAUNER',
				file     => 't/local/mymodules/not-discoverable.tar.gz'
				);
  			} 'Ok without module/version when specified';
  		};

	subtest 'needs module and version when not discoverable' => sub {
		dies_ok {
			$mcpi->add(
				authorid => 'RWSTAUNER',
				file     => 't/local/mymodules/not-discoverable.tar.gz'
				);
			} 'Dies without module/version when not discoverable';
		};
	};

subtest 'remote problems' => sub {
	my $repo_dir = catfile $temp_dir, 'injects';
	subtest 'create repo dir' => sub {
		ok make_path($repo_dir), 'created repo dir' unless -d $repo_dir;
		chmod 0755, $repo_dir;
		is mode($repo_dir), 0755, 'repo dir has mode 755' if has_modes();
		ok -r $repo_dir, 'repo dir is readable';
		ok -w $repo_dir, 'repo dir is writable';
		};

	subtest 'unreachable remote' => sub {
		my $unreachable_host = 'com';
		my $url = 'http://$host/';

		my ($lookup_error, @result) = getaddrinfo $unreachable_host, 'http';

diag( Dumper(\@result) ); use Data::Dumper;

		SKIP: {
			plan skip_all => 'bad host resolves, so cannot test that'
				unless $lookup_error;

			my $tmp_config_file = catfile $temp_dir, 'good_config';
			subtest 'create config file' => sub {
				my $fh;
				if(open $fh, '>', $tmp_config_file) {
					print {$fh} <<"HERE";
local: $temp_dir
remote: $url
repository: $repo_dir
dirmode: 0775
passive: yes
HERE
					close $fh;
					ok -e $tmp_config_file, 'config file exists';
					ok -r $tmp_config_file, 'config file is readable';
					}
				else {
					fail("Could not create config file");
					}
				};

			my $mcpi = $class->new;
			isa_ok $mcpi, $class;
			lives_ok { $mcpi->parsecfg( $tmp_config_file ) } 'parsecfg works';
			diag "trying to connect to a bad site: this might take a minute";
			dies_ok { $mcpi->testremote } 'No reachable site';
			like $@, qr/Unable to connect/, 'exception has expected message';
			}
		};
	};

# writelist()
subtest 'writelist' => sub {
	SKIP: {
		skip 'User is superuser and can always write', 1 if $< == 0;
		skip 'User is generally superuser under cygwin and can write', 1 if $^O eq 'cygwin';

		my $repo_dir = catfile $temp_dir, 'injects';
		subtest 'create repo dir' => sub {
			ok make_path($repo_dir), 'created repo dir' unless -d $repo_dir;
			chmod 0555, $repo_dir;
			is mode($repo_dir), 0555, 'repo dir has mode 555';
			ok -r $repo_dir, 'repo dir is readable';
			ok ! -w $repo_dir, 'repo dir is not writable';
			};

		my $tmp_config_file = catfile $temp_dir, 'config';
		subtest 'create config file' => sub {
			my $fh;
			if(open $fh, '>', $tmp_config_file) {
				print {$fh} <<"HERE";
local: $temp_dir
remote : http://www.cpan.org
repository: $repo_dir
HERE
				close $fh;
				ok -e $tmp_config_file, 'config file exists';
				ok -r $tmp_config_file, 'config file is readable';
				}
			else {
				fail("Could not create config file");
				}
			};

		my $mcpi = $class->new;
		isa_ok $mcpi, $class;
		lives_ok { $mcpi->parsecfg( $tmp_config_file ) } 'parsecfg works';
		dies_ok { $mcpi->writelist } 'fail write file';
		like $@, qr//, 'exception has expected message';
		}
	};

done_testing();
