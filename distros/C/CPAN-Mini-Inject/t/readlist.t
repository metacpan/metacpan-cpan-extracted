use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec::Functions qw(catfile);
use File::Temp;

use Test::More;

my $class = 'CPAN::Mini::Inject';

subtest 'sanity' => sub {
	use_ok $class or BAIL_OUT("$class did not compile: $@");
	can_ok $class, 'new';
	};

$SIG{'INT'} = sub { print "\nCleaning up before exiting\n"; exit 1 };
my $temp_dir = File::Temp::tempdir(CLEANUP=>1);

my $tmp_config_file = catfile $temp_dir, 'config';
my $repo_dir = catfile $temp_dir, 'injects';

subtest 'make repo dir' => sub {
	make_path $repo_dir;
	ok -e $repo_dir, "repository directory exists";
	};

subtest 'make config' => sub {
	my $fh;
	if( open $fh, '>', $tmp_config_file ) {
		print {$fh} <<"HERE";
local: $temp_dir
remote : http://localhost:11027
repository: $repo_dir
dirmode: 0775
passive: yes
HERE
		close $fh;
		pass( "created config file" );
		}
	else {
		fail("Could not create config file. Cannot continue");
		done_testing();
		exit;
		}
	};

subtest 'make modulelist' => sub {
	my $modulelist_path = catfile $repo_dir, 'modulelist';
	my $fh;
	if( open $fh, '>', $modulelist_path ) {
		print {$fh} <<"HERE";
CPAN::Checksums                   1.016  A/AN/ANDK/CPAN-Checksums-1.016.tar.gz
CPAN::Mini                         0.18  R/RJ/RJBS/CPAN-Mini-0.18.tar.gz
CPANPLUS                         0.0499  A/AU/AUTRIJUS/CPANPLUS-0.0499.tar.gz
HERE
		close $fh;
		pass( "created modulelist file" );
		}
	else {
		fail("Could not create modulelist file. Cannot continue");
		done_testing();
		exit;
		}
	};

subtest 'readlist' => sub {
	my $mcpi = $class->new;
	isa_ok $mcpi, $class;
	can_ok $mcpi, 'readlist';

	ok -e $tmp_config_file, 'config file exists';
	ok $mcpi->loadcfg( $tmp_config_file )->parsecfg, 'parsecfg succeeded';
	ok ! exists $mcpi->{modulelist}, "object does not have modulelist key yet";

	$mcpi->readlist;
	ok exists $mcpi->{modulelist}, "object has modulelist key after readlist";
	isa_ok $mcpi->{modulelist}, ref [], 'modulelist is an array ref after readlist';

	is( @{ $mcpi->{modulelist} }, 3, 'read modulelist' );
	};

done_testing();
