# launch app-daemon
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Sysadm::Install qw(:all);
use Test::More;
use App::Daemon;

use Log::Log4perl qw(:easy);
# Log::Log4perl->easy_init($DEBUG);

plan tests => 6;

my $tempdir = tempdir( CLEANUP => 1 );

my ( $stdout, $stderr, $rc );
my @cmdline = ( $^X, "-I$Bin/../blib/lib", "$Bin/../eg/test-daemon",
               "-l", "$tempdir/log", "-p", "$tempdir/pid" );

  # start sleep daemon
( $stdout, $stderr, $rc ) = tap @cmdline, "start";
is $rc, 0, "app start";

  # start once again
( $stdout, $stderr, $rc ) = tap @cmdline, "start";
is $rc>>8, App::Daemon::ALREADY_RUNNING, "app start again";

  # check status
( $stdout, $stderr, $rc ) = tap @cmdline, "status";
is $rc>>8, App::Daemon::LSB_OK, "status started";

  # stop daemon
( $stdout, $stderr, $rc ) = tap @cmdline, "stop";
is $rc, 0, "app stop";

  # stop daemon again
( $stdout, $stderr, $rc ) = tap @cmdline, "stop";
is $rc>>8, App::Daemon::LSB_NOT_RUNNING, "app stop again";

  # check status
( $stdout, $stderr, $rc ) = tap @cmdline, "status";
is $rc>>8, App::Daemon::LSB_NOT_RUNNING, "status stopped";

