# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Ceph-Rados.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Ceph::Rados') };


my $fail = 0;
foreach my $constname (qw(
	CEPH_OSD_TMAP_CREATE CEPH_OSD_TMAP_HDR CEPH_OSD_TMAP_RM
	CEPH_OSD_TMAP_SET LIBRADOS_CMPXATTR_OP_EQ LIBRADOS_CMPXATTR_OP_GT
	LIBRADOS_CMPXATTR_OP_GTE LIBRADOS_CMPXATTR_OP_LT
	LIBRADOS_CMPXATTR_OP_LTE LIBRADOS_CMPXATTR_OP_NE
	LIBRADOS_CREATE_EXCLUSIVE LIBRADOS_CREATE_IDEMPOTENT
	LIBRADOS_LOCK_FLAG_RENEW LIBRADOS_OPERATION_BALANCE_READS
	LIBRADOS_OPERATION_IGNORE_CACHE LIBRADOS_OPERATION_IGNORE_OVERLAY
	LIBRADOS_OPERATION_LOCALIZE_READS LIBRADOS_OPERATION_NOFLAG
	LIBRADOS_OPERATION_ORDER_READS_WRITES LIBRADOS_OPERATION_SKIPRWLOCKS
	LIBRADOS_OP_FLAG_EXCL LIBRADOS_OP_FLAG_FAILOK LIBRADOS_SNAP_DIR
	LIBRADOS_SNAP_HEAD LIBRADOS_SUPPORTS_WATCH LIBRADOS_VERSION_CODE
	LIBRADOS_VER_EXTRA LIBRADOS_VER_MAJOR LIBRADOS_VER_MINOR)) {
  next if (eval "my \$a = Ceph::Rados::$constname(); 1");
  if ($@ =~ /^Your vendor has not defined Ceph::Rados macro $constname/) {
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

