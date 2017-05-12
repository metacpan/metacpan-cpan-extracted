use strict;
use warnings;

BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        unshift @INC, '../lib';
    }
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

use ExtUtils::testlib;

use omnithreads;

BEGIN {
    eval {
        require omnithreads::shared;
        import omnithreads::shared;
    };
    if ($@ || ! $omnithreads::shared::threads_shared) {
        print("1..0 # Skip: omnithreads::shared not available\n");
        exit(0);
    }

    $| = 1;
    print("1..78\n");   ### Number of tests that will be run ###
};

my $TEST;
BEGIN {
    share($TEST);
    $TEST = 1;
}

ok(1, 'Loaded');

sub ok {
    my ($ok, $name) = @_;

    lock($TEST);
    my $id = $TEST++;

    # You have to do it this way or VMS will get confused.
    if ($ok) {
        print("ok $id - $name\n");
    } else {
        print("not ok $id - $name\n");
        printf("# Failed test at line %d\n", (caller)[2]);
    }

    return ($ok);
}


### Start of Testing ###

# Tests freeing the Perl interperter for each thread
# See http://www.nntp.perl.org/group/perl.perl5.porters/110772 for details

my $COUNT;
share($COUNT);
my %READY;
share(%READY);

# Init a thread
sub th_start {
    my $tid = omnithreads->tid();
    ok($tid, "Thread $tid started");

    omnithreads->yield();

    my $other;
    {
        lock(%READY);

        # Create next thread
        if ($tid < 17) {
            my $next = 'th' . ($tid+1);
            my $th = omnithreads->create($next);
        } else {
            # Last thread signals first
            th_signal(1);
        }

        # Wait until signalled by another thread
        while (! exists($READY{$tid})) {
            cond_wait(%READY);
        }
        $other = delete($READY{$tid});
    }
    ok($tid, "Thread $tid received signal from $other");
    omnithreads->yield();
}

# Thread terminating
sub th_done {
    my $tid = omnithreads->tid();

    lock($COUNT);
    $COUNT++;
    cond_signal($COUNT);

    ok($tid, "Thread $tid done");
}

# Signal another thread to go
sub th_signal
{
    my $other = shift;
    my $tid = omnithreads->tid();

    ok($tid, "Thread $tid signalling $other");

    lock(%READY);
    $READY{$other} = $tid;
    cond_broadcast(%READY);
}

#####

sub th1 {
    th_start();

    omnithreads->detach();

    th_signal(2);
    th_signal(6);
    th_signal(10);
    th_signal(14);

    th_done();
}

sub th2 {
    th_start();
    omnithreads->detach();
    th_signal(4);
    th_done();
}

sub th6 {
    th_start();
    omnithreads->detach();
    th_signal(8);
    th_done();
}

sub th10 {
    th_start();
    omnithreads->detach();
    th_signal(12);
    th_done();
}

sub th14 {
    th_start();
    omnithreads->detach();
    th_signal(16);
    th_done();
}

sub th4 {
    th_start();
    omnithreads->detach();
    th_signal(3);
    th_done();
}

sub th8 {
    th_start();
    omnithreads->detach();
    th_signal(7);
    th_done();
}

sub th12 {
    th_start();
    omnithreads->detach();
    th_signal(13);
    th_done();
}

sub th16 {
    th_start();
    omnithreads->detach();
    th_signal(17);
    th_done();
}

sub th3 {
    my $tid = omnithreads->tid();
    my $other = 5;

    th_start();
    omnithreads->detach();
    th_signal($other);
    sleep(1);
    ok(1, "Thread $tid getting return from thread $other");
    my $ret = omnithreads->object($other)->join();
    ok($ret == $other, "Thread $tid saw that thread $other returned $ret");
    th_done();
}

sub th5 {
    th_start();
    th_done();
    return (omnithreads->tid());
}


sub th7 {
    my $tid = omnithreads->tid();
    my $other = 9;

    th_start();
    omnithreads->detach();
    th_signal($other);
    ok(1, "Thread $tid getting return from thread $other");
    my $ret = omnithreads->object($other)->join();
    ok($ret == $other, "Thread $tid saw that thread $other returned $ret");
    th_done();
}

sub th9 {
    th_start();
    sleep(1);
    th_done();
    return (omnithreads->tid());
}


sub th13 {
    my $tid = omnithreads->tid();
    my $other = 11;

    th_start();
    omnithreads->detach();
    th_signal($other);
    sleep(1);
    ok(1, "Thread $tid getting return from thread $other");
    my $ret = omnithreads->object($other)->join();
    ok($ret == $other, "Thread $tid saw that thread $other returned $ret");
    th_done();
}

sub th11 {
    th_start();
    th_done();
    return (omnithreads->tid());
}


sub th17 {
    my $tid = omnithreads->tid();
    my $other = 15;

    th_start();
    omnithreads->detach();
    th_signal($other);
    ok(1, "Thread $tid getting return from thread $other");
    my $ret = omnithreads->object($other)->join();
    ok($ret == $other, "Thread $tid saw that thread $other returned $ret");
    th_done();
}

sub th15 {
    th_start();
    sleep(1);
    th_done();
    return (omnithreads->tid());
}


TEST_STARTS_HERE:
{
    $COUNT = 0;
    omnithreads->create('th1');
    {
        lock($COUNT);
        while ($COUNT < 17) {
            cond_wait($COUNT);
        }
    }
    sleep(1);
}
ok($COUNT == 17, "Done - $COUNT threads");

# EOF
