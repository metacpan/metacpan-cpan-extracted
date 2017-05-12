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
    print("1..5\n");   ### Number of tests that will be run ###
};

my ($TEST, $COUNT, $TOTAL);

BEGIN {
    share($TEST);
    $TEST = 1;
    share($COUNT);
    $COUNT = 0;
    $TOTAL = 0;
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
        print(STDERR "# FAIL: $name\n") if (! exists($ENV{'PERL_CORE'}));
    }

    return ($ok);
}


### Start of Testing ###

$SIG{'__WARN__'} = sub { ok(0, "Warning: $_[0]"); };

sub foo { lock($COUNT); $COUNT++; }
sub baz { 42 }

my $bthr;
BEGIN {
    $SIG{'__WARN__'} = sub { ok(0, "BEGIN: $_[0]"); };

    $TOTAL++;
    omnithreads->create('foo')->join();
    $TOTAL++;
    omnithreads->create(\&foo)->join();
    $TOTAL++;
    omnithreads->create(sub { lock($COUNT); $COUNT++; })->join();

    $TOTAL++;
    omnithreads->create('foo')->detach();
    $TOTAL++;
    omnithreads->create(\&foo)->detach();
    $TOTAL++;
    omnithreads->create(sub { lock($COUNT); $COUNT++; })->detach();

    $bthr = omnithreads->create('baz');
}

my $mthr;
MAIN: {
    $TOTAL++;
    omnithreads->create('foo')->join();
    $TOTAL++;
    omnithreads->create(\&foo)->join();
    $TOTAL++;
    omnithreads->create(sub { lock($COUNT); $COUNT++; })->join();

    $TOTAL++;
    omnithreads->create('foo')->detach();
    $TOTAL++;
    omnithreads->create(\&foo)->detach();
    $TOTAL++;
    omnithreads->create(sub { lock($COUNT); $COUNT++; })->detach();

    $mthr = omnithreads->create('baz');
}

ok($mthr, 'Main thread');
ok($bthr, 'BEGIN thread');

ok($mthr->join() == 42, 'Main join');
ok($bthr->join() == 42, 'BEGIN join');

# Wait for detached threads to finish
{
    omnithreads->yield();
    sleep(1);
    lock($COUNT);
    redo if ($COUNT < $TOTAL);
}

# EOF
