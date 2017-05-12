use t::lib;
use strict;
use Test::More;
use Class::AutoDB;
use autodbUtil;
use autodbRunTests;

# Regression test: put large complex graph. breaks Dumper 2.121
# I don't know why this particular structure is problematic. not just size...
#   big arrays or hashes don't break it
#   ternary trees with depth <= 3 don't break it
#   in this test, binary trees with depth <= 5 don't break it

# make sure max_allowed_packet big enough. code adapted from graphUtil
# value used here (6 MB) determined empirically. may have to change if graphs change!!
# NG 10-03-08: turns out that changing max_allowed_packet has no effect despite
#              what the MySQL documentations says...
my $autodb=new Class::AutoDB(-database=>testdb); # open database
my $dbh=$autodb->dbh;
my($name,$max_allowed_packet)=
  $dbh->selectrow_array(qq(SHOW VARIABLES LIKE 'max_allowed_packet'));
diag "max_allowed_packet=$max_allowed_packet";
my $min=6*1024*1024;
unless ($max_allowed_packet>=$min) {
  # $dbh->do(qq(SET max_allowed_packet=$min));
  # ($name,$max_allowed_packet)=$dbh->selectrow_array(qq(SHOW VARIABLES LIKE 'max_allowed_packet'));
  # diag "max_allowed_packet after set=$max_allowed_packet";
  # # skip tests if didn't work
  # unless ($max_allowed_packet>=$min) {
  diag "max_allowed_packet=$max_allowed_packet too small. must be >= $min";
  ok(1);			# need at least 1 test to run
  done_testing();
  exit;
}
# }

runtests_main();
