use Test::More tests => 3;

use App::Daemon qw(daemonize cmd_line_parse);
use File::Temp qw(tempfile);
use Fcntl qw/:flock/;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init({ level => $DEBUG, layout => "%F-%L> %m%n" });

my($fh, $tempfile) = tempfile();

  # Turdix locks temp files, so unlock them just in case
flock $fh, LOCK_UN;

ok(1, "loaded ok");

open(OLDERR, ">&STDERR");
open(STDERR, ">$tempfile");

@ARGV = ("-X");
daemonize();

close STDERR;
open(STDERR, ">&OLDERR");
close OLDERR;

ok(1, "Running in foreground with -X");

open FILE, "<$tempfile" or
    die "Cannot open tempfile $tempfile ($!)";
my $data = join '', <FILE>;
close FILE;

like($data, qr/Running in foreground/, "log message");
