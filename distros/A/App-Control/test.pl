# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use App::Control;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

eval {
    warn "Creating new App::Control object\n";
    my $exec = 'sample/test.pl';
    my $pidfile = 'pids/test.pid';
    my $ctl = App::Control->new(
        EXEC => $exec,
        ARGS => [ $pidfile ],
        PIDFILE => $pidfile,
        VERBOSE => 1,
    ) or die "failed to create new App::Control object\n";
    die $ctl->pid, "running\n" if $ctl->running;
    warn "test start ...\n";
    $ctl->start;
    die "Not running\n" unless $ctl->running;
    warn "test status ...\n";
    warn $ctl->status;
    warn "test stop ...\n";
    $ctl->stop;
    die "Still running\n" if $ctl->running;
    warn "test restart after stop ...\n";
    $ctl->restart;
    die "Not running\n" unless $ctl->running;
    warn "test restart after start ...\n";
    $ctl->stop;
    $ctl->start;
    $ctl->restart;
    die "Not running\n" unless $ctl->running;
    warn "cleaning up ...\n";
    $ctl->stop;
    die "Still running\n" if $ctl->running;
    unlink( $pidfile ) or die "Can't remove pidfile $pidfile\n";
    my $ignore_file = 'ignore.tmp';
    die "can't create $ignore_file\n" unless open( FH, ">$ignore_file" );
    close( FH );
    my $ctl = App::Control->new(
        IGNOREFILE => 'ignore.tmp',
        EXEC => $exec,
        ARGS => [ $pidfile ],
        PIDFILE => $pidfile,
        VERBOSE => 1,
    ) or die "failed to create new App::Control object\n";
    warn "test ignore ...\n";
    $ctl->start;
    die $ctl->pid, "running\n" if $ctl->running;
    unlink( $ignore_file );
    $ctl->start;
    die $ctl->pid, " not running\n" unless $ctl->running;
    $ctl->hup;
    die $ctl->pid, " not running\n" unless $ctl->running;
    $ctl->stop;
    die "Still running\n" if $ctl->running;
};
if ( $@ )
{
    warn $@;
    print "not ";
}
print "ok 2\n";
