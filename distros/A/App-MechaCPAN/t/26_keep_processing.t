use strict;
use FindBin;
use Test::More;
use Config;
use Cwd qw/cwd/;
use File::Temp qw/tempdir/;

require q[./t/helper.pm];

my $pwd    = cwd;
my $dista  = "$FindBin::Bin/../test_dists/FailTests/FailTests-1.0.tar.gz";
my $distb  = "$FindBin::Bin/../test_dists/NoDeps/NoDeps-1.0.tar.gz";
my $tmpdir = tempdir( TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX", CLEANUP => 1 );
chdir $tmpdir;

local $SIG{__WARN__} = sub { note shift };

my $dir = cwd;

# --no-update
{
  my $dist = 'Test::More';
  no strict 'refs';
  no warnings 'redefine';
  my $ran_configure = 0;
  local *App::MechaCPAN::Install::_configure = sub { die ++$ran_configure };
  local $@;

  eval { App::MechaCPAN::main( 'install', $dist ) };
  is( $ran_configure, 1, "Did try and install $dist by itself" );

  $ran_configure = 0;
  eval { App::MechaCPAN::main( 'install', $dista, $distb ) };
  is( $ran_configure, 2, "Attempted to install both $dista and $distb" );
}

chdir $pwd;
done_testing;

