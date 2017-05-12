
use File::Basename qw(dirname);
my $dirname = dirname($0);
if($dirname) {
    chdir($dirname) || die("can't chdir to $dirname: $!");
}		     
chdir('asp-perl') || die("can't chdir to asp-perl");

@ARGV = ('-b', 'ok.inc');
use lib qw(../../blib/lib ../../lib);
do "../../asp-perl";
