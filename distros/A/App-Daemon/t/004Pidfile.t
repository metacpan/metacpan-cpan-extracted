use warnings;
use strict;
use Test::More tests => 5;
use File::Temp qw( tempdir );
use Sysadm::Install qw(:all);
use FindBin qw( $Bin );

use App::Daemon qw(daemonize cmd_line_parse);
use Fcntl qw/:flock/;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init({ level => $DEBUG, layout => "%F-%L> %m%n" });

my $tempdir = tempdir( CLEANUP => 1 );

my ( $stdout, $stderr, $rc );

my $pidfile = "$tempdir/pid";
my $logfile = "$tempdir/log";

my @cmdline = ( $^X, "-I$Bin/../blib/lib", "$Bin/../eg/test-fork-daemon",
               "-l", $logfile, "-p", $pidfile, "-v" );

( $stdout, $stderr, $rc ) = tap @cmdline, "start";
is $rc, 0, "app start";

  # wait until process is up
while( 1 ) {
    DEBUG "Checking for logfile";
    if( -f $logfile ) {
        ok 1, "daemon started";
        last;
    }
    sleep 1;
}

  # wait until child exits     
while( 1 ) {
    my $data = slurp $logfile;
    DEBUG "Checking logfile for 'waitpid done': [$data]";
    if( $data =~ /parent waitpid done/ ) {
        ok 1, "parent waitpid done";
        last;
    }
    sleep 1;
}

ok -f $pidfile, "pidfile still exists after child exit";

( $stdout, $stderr, $rc ) = tap @cmdline, "stop";
is $rc, 0, "app stop";

# print slurp( $logfile );
