# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Crypt-HC128.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test;
BEGIN { plan tests => 2 };
use Crypt::HC128;
ok(1); # If we made it this far, we're ok.


my $fail;
foreach my $constname (qw(
	HC128_ENC_TYPE)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Crypt::HC128 macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }
}
if ($fail) {
  print "not ok 2\n";
} else {
  print "ok 2\n";
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

