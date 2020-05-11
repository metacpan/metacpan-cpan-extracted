# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Ceph-Rados-Striper.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Ceph::Rados::Striper') };


my $fail = 0;
foreach my $constname (qw(
	LIBRADOSSTRIPER_VERSION_CODE LIBRADOSSTRIPER_VER_EXTRA
	LIBRADOSSTRIPER_VER_MAJOR LIBRADOSSTRIPER_VER_MINOR)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Ceph::Rados::Striper macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

