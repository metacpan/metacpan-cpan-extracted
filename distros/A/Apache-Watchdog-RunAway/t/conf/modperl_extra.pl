
use Apache::Watchdog::RunAway ();
use File::Spec::Functions qw(catfile);
use Apache::Test;

my $hostport = Apache::TestRequest::hostport(Apache::Test::config());
my $retrieve_url = "http://$hostport/scoreboard";

my $t_logs = Apache::Test::vars('t_logs');

$Apache::Watchdog::RunAway::TIMEOUT = 20;
$Apache::Watchdog::RunAway::POLLTIME = 1;
$Apache::Watchdog::RunAway::DEBUG = 2;
$Apache::Watchdog::RunAway::LOCK_FILE = catfile $t_logs, "safehang.lock";
$Apache::Watchdog::RunAway::LOG_FILE = catfile $t_logs, "safehang.log";
$Apache::Watchdog::RunAway::SCOREBOARD_URL = $retrieve_url;
$Apache::Watchdog::RunAway::VERBOSE = 0;

warn "The monitor will use URL: $retrieve_url\n";

# cleanup any remainder from the last test
Apache::Watchdog::RunAway::stop_monitor();

# forks a monitor
Apache::Watchdog::RunAway::start_detached_monitor();

# comment out the following line and watch t/log/safehang.log for
# what's monitor is doing

# kills a monitor
Apache::Watchdog::RunAway::stop_monitor();

1;
