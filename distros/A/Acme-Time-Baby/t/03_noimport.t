# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN {
    if ($] eq '5.009005') {
        print "1..1\n";
        print "# This is for silly CPAN testers running 5.9.5.\n";
        print "ok 1\n";
        exit;
    }
}

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use strict;
BEGIN { plan tests => 2 }
use Acme::Time::Baby noimport => 1;
ok(1); # If we made it this far, we're ok.

ok (not defined &babytime);
