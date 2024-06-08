use strict;
use warnings;

use Test::More;

use File::Path qw(make_path);
use File::Spec::Functions qw(catfile);
use File::Temp ();

use lib qw(t/lib);
use Local::utils;

my $class = 'CPAN::Mini::Inject';

$SIG{'INT'} = sub { print "\nCleaning up before exiting\n"; exit 1 };
my $temp_dir = File::Temp::tempdir(CLEANUP=>1);

subtest 'sanity' => sub {
	use_ok $class or BAIL_OUT( "Could not load $class: $@" );
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

my $modulelist;
subtest 'make modulelist' => sub {
	my $injects_dir = catfile $temp_dir, 'injects';
	ok -e $injects_dir, 'injects directory exists';

	$modulelist = catfile $injects_dir, 'modulelist';

	my $fh;
	if( open $fh, '>', catfile $modulelist ) {
		print {$fh} <<'HERE';
CPAN::Checksums                   1.016  A/AN/ANDK/CPAN-Checksums-1.016.tar.gz
CPAN::Mini                         0.18  R/RJ/RJBS/CPAN-Mini-0.18.tar.gz
CPANPLUS                         0.0499  A/AU/AUTRIJUS/CPANPLUS-0.0499.tar.gz
HERE

		close $fh;
		}
	else {
		fail( "Could not open <$modulelist>: $!" );
		}
	};

subtest 'add to modulelist' => sub {
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

	$mcpi->loadcfg( $tmp_config_file )->parsecfg->readlist;

	my $module_line = "CPAN::Mini::Inject                 0.01  S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz";

	subtest 'modify modulelist' => sub {
		ok -e $modulelist, "modulelist file exists";
		push( @{ $mcpi->{modulelist} }, $module_line );
		is( @{ $mcpi->{modulelist} }, 4, 'Updated memory modulelist' );
		ok( $mcpi->writelist, 'Write modulelist' );
		};

	subtest 'check modulelist' => sub {
		my $other_mcpi = $class->new;
		isa_ok $other_mcpi, $class;
		$mcpi->loadcfg( $tmp_config_file )->parsecfg->readlist;

		is( @{ $mcpi->{modulelist} }, 4, 'Updated memory modulelist' );
		my $found = grep { $_ eq $module_line } @{ $mcpi->{modulelist} };
		ok $found, "target line is in modulelist";
		};

	};

done_testing();

