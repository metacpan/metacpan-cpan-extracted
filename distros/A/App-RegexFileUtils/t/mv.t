use Test2::V0 -no_srand => 1;
use App::RegexFileUtils;
use File::Temp qw( tempdir );
use File::Spec;

skip_all 'only test on MSWin32' unless $^O eq 'MSWin32';

my $dir = tempdir( CLEANUP => 1 );

ok -d $dir, "dir = $dir";

my $subdir = File::Spec->catdir($dir, 'subdir');

mkdir $subdir;

ok -d $subdir, "subdir = $subdir";

my $mv    = File::Spec->catfile(App::RegexFileUtils->_share_dir, 'ppt', 'mv.pl');
my $touch = File::Spec->catfile(App::RegexFileUtils->_share_dir, 'ppt', 'touch.pl');

system $^X, $touch, File::Spec->catfile($dir, 'A01.txt');
system $^X, $touch, File::Spec->catfile($dir, 'A02.txt');
system $^X, $touch, File::Spec->catfile($dir, 'A03.txt');

ok -e File::Spec->catfile($dir, 'A01.txt'), "A01";
ok -e File::Spec->catfile($dir, 'A02.txt'), "A02";
ok -e File::Spec->catfile($dir, 'A03.txt'), "A03";

system $^X, $mv, File::Spec->catfile($dir, 'A01.txt'), File::Spec->catfile($dir, 'B01.txt');

ok ! -e File::Spec->catfile($dir, 'A01.txt'), "A01";
ok -e File::Spec->catfile($dir, 'B01.txt'), "B01";
ok -e File::Spec->catfile($dir, 'A02.txt'), "A02";
ok -e File::Spec->catfile($dir, 'A03.txt'), "A03";

system $^X, $mv, File::Spec->catfile($dir, 'A02.txt'), File::Spec->catfile($dir, 'A03.txt'), File::Spec->catdir($dir, 'subdir');

ok ! -e File::Spec->catfile($dir, 'A01.txt'), "A01";
ok -e File::Spec->catfile($dir, 'B01.txt'), "B01";
ok ! -e File::Spec->catfile($dir, 'A02.txt'), "A02";
ok ! -e File::Spec->catfile($dir, 'A03.txt'), "A03";
ok -e File::Spec->catfile($dir, 'subdir', 'A02.txt'), "A02";
ok -e File::Spec->catfile($dir, 'subdir', 'A03.txt'), "A03";

done_testing;
