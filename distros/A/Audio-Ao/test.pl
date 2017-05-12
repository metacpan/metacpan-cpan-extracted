# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 6 };
use Audio::Ao qw(:all);
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
ok(initialize_ao(), undef);
print "If #3 fails & you're on a big endian machine, don't worry.\n";
ok(is_big_endian(), 0);
ok(driver_info_list());
ok(my $dr = driver_info(default_driver_id));
ok(shutdown_ao(), undef);
# not testing the rest cause we're mostly just seeing if the library
# is detected and testing the open and play functions is a pain
