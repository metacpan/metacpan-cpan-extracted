use strict;
use FindBin;
use Test::More;
BEGIN { diag("(BEGIN) Try::Tiny => $INC{'Try/Tiny.pm'}"); }
use Config;
use Cwd qw/cwd/;
use File::Temp qw/tempdir/;

require q[./t/helper.pm];

my $pwd = cwd;

my $tmpdir = tempdir( TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX", CLEANUP => 1 );
chdir $tmpdir;
my $dir = cwd;

my $lib     = 'ConfigDeps';
my $deplib  = 'Try/Tiny';
my $options = {
  source => {
    $lib        => "$pwd/test_dists/$lib/$lib-1.0.tar.gz",
    'Try::Tiny' => 'E/ET/ETHER/Try-Tiny-0.24.tar.gz',
  },
};

diag("cwd => $dir");
diag("Try::Tiny => $INC{'Try/Tiny.pm'}");

is( App::MechaCPAN::Install->go( $options, "$lib" ), 0, 'Can use a source' );
diag("Try::Tiny => $INC{'Try/Tiny.pm'}");
is( cwd, $dir, 'Returned to whence it started' );

ok( -e "$dir/local/lib/perl5/$lib.pm", "Library file $lib exists" );
ok( -e "$dir/local/lib/perl5/$deplib.pm", "Library file $deplib exists" );
diag("Try::Tiny => $INC{'Try/Tiny.pm'}");

{
  # Silence warnings for the require_ok. If the user has LWP installed, then
  # it will cause harmless warnings about redefined subs. These don't cause
  # errors and just add to the noise in cpantesters.
  local $SIG{__WARN__} = sub {};
  require_ok("$dir/local/lib/perl5/$deplib.pm");
}

diag("Try::Tiny => $INC{'Try/Tiny.pm'}");
is( $Try::Tiny::VERSION, '0.24', "The correct version was installed" );

chdir $pwd;
done_testing;
