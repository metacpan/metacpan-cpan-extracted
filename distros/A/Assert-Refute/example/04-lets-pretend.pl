#!/usr/bin/env perl

# Let's pretend this is a big "enterprise" application
# with lots of modules and stuff.

use strict;
use warnings;
use POSIX qw(strftime);
use Assert::Refute { on_fail => 'carp' };

# Let's pretend this is a huge enterprise logger (syslog, log4perl, or both)
$SIG{__WARN__} = sub {
    my $mess = shift;
    chomp $mess;
    printf STDERR "%s %s[%d] WARN %s\n",
        strftime( "%Y-%m-%dT%H:%M:%S", localtime ), $0, $$, $mess;
};

# Let's pretend this is a big loop with convoluted logic
#    iterating over tons of user-supplied data
for my $num (1 .. 100) {
    # Let's pretend we skipped a lot of processing here
    # and a database request we can't currently replicate in unit tests
    # and more processing

    # <----- HERE!!!
    # Now we want to add some runtime checks on top of that
    #    so that we know right away when our assumptions don't hold
    try_refute {
        my $report = shift; # a report object

        # Let's pretend we have less stupid conditions being checked
        #    like the fact that $total == $price * $quantity + $fee
        #    or some object actually can TO_JSON and won't become just 'null'

        # But generally here we have a runtime assertion DSL mirroring
        #    the interface of Test::More & co
        #    which is by far the most convenient way
        #    to describe _behavior_ in Perl.
        $report->diag( "verifying number $num" );
        $report->ok( $num % 17, "No number is divisible by 17 (TODO only checked first ten)");
        $report->isnt( $num, 42, "No number is 42" );
    };
    # Now at this point on_fail callback has fired if conditions are not met
    #    and the application continues business as usual
    #    because spice must flow!
};

# Let's pretend this is not the end of our Big Enterprise Application (tm)
__END__
