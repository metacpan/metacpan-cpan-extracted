use strict;
use FindBin;
use File::Copy;
use Test::More;
use Cwd qw/cwd/;
use File::Temp qw/tempdir/;

require q[./t/helper.pm];

my $pwd      = cwd;
my $cpanfile = "$FindBin::Bin/../test_dists/DeploySnapshot/cpanfile";

my $tmpdir = tempdir( TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX", CLEANUP => 1 );
chdir $tmpdir;
my $dir = cwd;

is(
  App::MechaCPAN::main( 'deploy', { 'skip-perl' => 1 }, $cpanfile ), 0,
  "Can run deploy"
);
is( cwd, $dir, 'Returned to whence it started' );
ok( -d "$dir/local/lib/perl5/", 'Created local lib' );

my $lib = 'Try/Tiny.pm';
ok( -e "$dir/local/lib/perl5/$lib", "Library file $lib exists" );

{
  # Silence warnings for the require_ok. If the user has LWP installed, then
  # it will cause harmless warnings about redefined subs. These don't cause
  # errors and just add to the noise in cpantesters.
  local $SIG{__WARN__} = sub {};
  require_ok("$dir/local/lib/perl5/$lib");
}

is( $Try::Tiny::VERSION, '0.24', "The correct version was installed" );

chdir $pwd;
done_testing;
