# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 3 };
use Class::Dynamic;
ok(1); # If we made it this far, we're ok.

our $testval = time & 1;

package A; sub number { return 12 }
package B; sub number { return 42 }

package C; @ISA = ( sub { $main::testval ? "A" : "B" } );
package D; @ISA = ( "A", sub { $main::testval ? "A" : "B" } );

package main;
ok (C->number == ($testval ? 12 : 42));
ok (D->number == 12);


#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

