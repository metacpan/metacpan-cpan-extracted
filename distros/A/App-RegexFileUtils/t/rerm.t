use Test2::V0 -no_srand => 1;
use File::Temp qw( tempdir );
use App::RegexFileUtils;
use File::Spec;

my $dir = tempdir( CLEANUP => 1);
chdir($dir) || die;

ok -d $dir, "dir = $dir";

for (qw( foo.txt bar.txt foo.txt.bak bar.txt~ test.txt test.txt.bak nerf.c nerf.c.bak ))
{ open my $fh, '>', $_; close $fh }

ok -e 'foo.txt', 'foo.txt';
ok -e 'bar.txt', 'bar.txt';
ok -e 'foo.txt.bak', 'foo.txt.bak';
ok -e 'bar.txt~', 'bar.txt~';
ok -e 'test.txt', 'test.txt';
ok -e 'test.txt.bak', 'test.txt.bak';
ok -e 'nerf.c', 'nerf.c';
ok -e 'nerf.c.bak', 'nerf.c.bak';

App::RegexFileUtils->main('rm', '/\\.bak$/');

ok -e 'foo.txt', 'foo.txt';
ok -e 'bar.txt', 'bar.txt';
ok ! -e 'foo.txt.bak', 'foo.txt.bak';
ok -e 'bar.txt~', 'bar.txt~';
ok -e 'test.txt', 'test.txt';
ok ! -e 'test.txt.bak', 'test.txt.bak';
ok -e 'nerf.c', 'nerf.c';
ok ! -e 'nerf.c.bak', 'nerf.c.bak';

chdir(File::Spec->updir) || die;

done_testing;
