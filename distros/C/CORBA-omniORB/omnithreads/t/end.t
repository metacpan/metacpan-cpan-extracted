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
    print("1..6\n");   ### Number of tests that will be run ###
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

# Test that END blocks are run in the thread that created them,
# and not in any child threads.

END {
    ok(1, 'Main END block')
}

omnithreads->create(sub { eval "END { ok(1, '1st thread END block') }"})->join();
omnithreads->create(sub { eval "END { ok(1, '2nd thread END block') }"})->join();

sub thread {
    eval "END { ok(1, '4th thread END block') }";
    omnithreads->create(sub { eval "END { ok(1, '5th thread END block') }"})->join();
}
omnithreads->create(\&thread)->join();

# EOF
