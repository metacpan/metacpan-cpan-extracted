
use File::Basename qw(dirname);
use Carp qw(cluck);

#$SIG{__WARN__} = \&cluck;

my $dirname = dirname($0);
if($dirname) {
    chdir($dirname) || die("can't chdir to $dirname: $!");
}		     

@ARGV = ('-b', '-f', 'asp-perl/asp.conf', 'asp-perl/ok.inc');
use lib qw(../blib/lib ../lib);
do "../asp-perl";
