use strict;
use FindBin;
use Test::More;
use Config;
use Cwd qw/cwd/;
use File::Temp qw/tempdir/;

require q[./t/helper.pm];

my $pwd  = cwd;
my $dist = 'Try::Tiny';
my $tmpdir  = tempdir( TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX", CLEANUP => 1 );
chdir $tmpdir;
my $dir = cwd;

is( App::MechaCPAN::main( 'install', $dist ), 0, "Can install $dist" );

{
  no strict 'refs';
  no warnings 'redefine';
  my $ran_configure = 0;
  local *App::MechaCPAN::Install::_configure = sub { $ran_configure = 1; undef };
  is(
    App::MechaCPAN::main( 'install', $dist ), 0,
    "Can rerun install $dist"
  );
  is( $ran_configure, 0, "Did not actually reininstall $dist" );
}

chdir $pwd;
done_testing;
