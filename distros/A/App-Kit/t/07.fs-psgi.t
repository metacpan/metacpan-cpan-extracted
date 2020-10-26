use Test::More;

use App::Kit;

my $app = App::Kit->new();

my $cwd   = $app->fs->cwd;
my $tdir  = $app->fs->tmpdir;
my $fsdir = $tdir->{'REALNAME'};    # necessary here to string-match bindir’s Cwd calls/logic results

chdir $fsdir || die "Could not go chdir to tmp dir: $!";
mkdir 'foo'  || die "Could not mkdir foo: $!";
my $foodir = $app->fs->spec->catdir( "$fsdir", 'foo' );
my $fsfile = $app->fs->spec->catfile( $foodir, 'test.psgi' );
$app->fs->write_file( $fsfile, "sub {}" );

{
    local $0 = 'starman worker -Ilib … foo/test.psgi';
    is $app->fs->bindir, $foodir, 'bindir w/ PSGI/Plack $0';
    is( $0, 'starman worker -Ilib … foo/test.psgi', '$0 not changed by bindir()' );
}

chdir $cwd || die "Could not go back to starting dir: $!";

done_testing;
