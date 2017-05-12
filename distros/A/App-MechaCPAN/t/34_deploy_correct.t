use strict;
use FindBin;
use File::Copy;
use Test::More;
use Cwd qw/cwd/;
use File::Temp qw/tempdir/;

require q[./t/helper.pm];

my $pwd      = cwd;
my $cpanfile = "$FindBin::Bin/../test_dists/DeployCpanfile/cpanfile";

my $tmpdir = tempdir( TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX", CLEANUP => 1 );
chdir $tmpdir;
my $dir = cwd;

is(
  App::MechaCPAN::main( 'deploy', { 'skip-perl' => 1 }, $cpanfile ), 0,
  "Can run deploy"
);
is( cwd, $dir, 'Returned to whence it started' );
ok( -d "$dir/local/lib/perl5/", 'Created local lib' );

foreach my $file ( 'Try/Tiny.pm' )
{
  ok( -e "$dir/local/lib/perl5/$file", "Library file $file exists" );
}

foreach my $file ( 'Test/More.pm' )
{
  ok( !-e "$dir/local/lib/perl5/$file", "Library file $file doesn't exists" );
}

chdir $pwd;
done_testing;
