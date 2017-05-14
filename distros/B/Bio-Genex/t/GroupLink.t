# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Spotter.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;



use lib 't';

use TestDB qw($TEST_USERSEC $TEST_GROUPSEC);
use Bio::Genex::GroupLink;
use Bio::Genex::UserSec;
use Bio::Genex::GroupSec;
use Bio::Genex;
$loaded = 1;
my $i = 1;
print "ok ", $i++, "\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# testing a random attribute
my $p = Bio::Genex::GroupLink->new();
$p->gs_fk(555);
if ($p->gs_fk() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# test fetch
$p = Bio::Genex::GroupLink->new(pkey_link=>'us_fk',id=>$TEST_USERSEC);
$p->fetch();
if ($p->gs_fk() eq $TEST_GROUPSEC){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

$p = Bio::Genex::GroupLink->new(pkey_link=>'gs_fk',id=>$TEST_GROUPSEC);
$p->fetch();
if ($p->us_fk() eq $TEST_USERSEC){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

1;

