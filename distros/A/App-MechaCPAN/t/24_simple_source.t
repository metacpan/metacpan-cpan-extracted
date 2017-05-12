use strict;
use FindBin;
use Test::More;
use Config;
use Cwd qw/cwd/;
use File::Temp qw/tempdir/;

require q[./t/helper.pm];

my $pwd = cwd;

my $tmpdir = tempdir( TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX", CLEANUP => 1 );
chdir $tmpdir;
my $dir = cwd;

my $lib     = 'NoDeps';
my $options = {
  source => {
    $lib => "$pwd/test_dists/$lib/$lib-1.0.tar.gz",
  },
};
is( App::MechaCPAN::Install->go( $options, "$lib" ), 0, 'Can use a source' );
is( cwd, $dir, 'Returned to whence it started' );

ok( -e "$dir/local/lib/perl5/$lib.pm", 'Library file $file exists' );

chdir $pwd;
done_testing;
