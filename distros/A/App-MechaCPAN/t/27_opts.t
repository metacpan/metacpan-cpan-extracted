use strict;
use FindBin;
use Test::More;
use Config;
use Cwd qw/cwd/;
use File::Temp qw/tempdir/;

require q[./t/helper.pm];

my $pwd  = cwd;
my $dist = "$FindBin::Bin/../test_dists/FailTests/FailTests-1.0.tar.gz";
my $tmpdir  = tempdir( TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX", CLEANUP => 1 );
chdir $tmpdir;

local $SIG{__WARN__} = sub {note shift};

my $dir = cwd;

# --skip-tests(-for)
{
  isnt( App::MechaCPAN::main( 'install', $dist ), 0, "Fail as expected: $dist" );
  is( cwd, $dir, 'Returned to whence it started' );

  is( App::MechaCPAN::main( '--skip-tests', 'install', $dist ), 0, "Skipped tests: $dist" );
  is( cwd, $dir, 'Returned to whence it started' );

  is( App::MechaCPAN::main( '--skip-tests-for', $dist, 'install', $dist ), 0, "Skipped tests for: $dist" );
  is( cwd, $dir, 'Returned to whence it started' );
}

# --no-update
{
  my $dist = 'Test::More';
  no strict 'refs';
  no warnings 'redefine';
  my $ran_configure = 0;
  local *App::MechaCPAN::Install::_configure = sub { die $ran_configure = 1 };
  local $@;

  eval { App::MechaCPAN::main( 'install', $dist ) };
  is( $ran_configure, 1, "Did try and install $dist by default" );

  $ran_configure = 0;
  eval { App::MechaCPAN::main( 'install', '--update', $dist ) };
  is( $ran_configure, 1, "Did try and install $dist when asked to" );

  $ran_configure = 0;
  eval { App::MechaCPAN::main( 'install', '--no-update', $dist ) };
  is( $ran_configure, 0, "Didn't try and install $dist when told not to upgrade" );
}

chdir $pwd;
done_testing;
