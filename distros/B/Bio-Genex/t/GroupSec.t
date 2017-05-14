# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl GroupSec.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $::loaded_gs;}
use Carp;



use lib 't';
use strict;
use TestDB qw($TEST_GROUPSEC $TEST_GROUPSEC_GROUP_NAME);
use Bio::Genex::GroupSec;
use Bio::Genex;
$::loaded_gs = 1;
my $i = 1;
print "ok ", $i++, "\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# testing a random attribute
my $c = new Bio::Genex::GroupSec;
$c->group_name(555);
if ($c->group_name() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# test fetch
$c = new Bio::Genex::GroupSec(id=>$TEST_GROUPSEC);
$c->fetch();
if ($c->group_name() eq $TEST_GROUPSEC_GROUP_NAME){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# test delayed_fetch
$c = new Bio::Genex::GroupSec(id=>$TEST_GROUPSEC);
if (not defined $c->get_attribute('group_name')){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

if ($c->group_name() eq $TEST_GROUPSEC_GROUP_NAME){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}


1;
