use Test2::V0 -no_srand => 1;
use File::Temp qw( tempdir );
use App::RegexFileUtils;
use Capture::Tiny qw( capture );
use File::Spec;

my $dir = tempdir( CLEANUP => 1);
chdir($dir) || die;

ok -d $dir, "dir = $dir";

my @orig = qw( foo01.jPg foo02.jpeg foo03.jPEG foo04.JPEG foo05.jpg );
for (@orig)
{ open my $fh, '>', $_; close $fh }

ok -e $_, "orig $_" for @orig;

capture sub { App::RegexFileUtils->main('mv', '/\.jpe?g/.jpg/i') };

ok -e "foo0$_.jpg", "after foo0$_.jpg" for (1..5);

chdir(File::Spec->updir) || die;

done_testing;
