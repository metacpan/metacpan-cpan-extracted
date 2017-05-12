# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Crypt-Discordian.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use Crypt::Discordian;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $string = 'hail eris';

$string = Crypt::Discordian::encrypt($string);
ok($string, 'AEHIILRS');
