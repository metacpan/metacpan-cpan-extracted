# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl UserSec.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $::loaded_gs;}
use Carp;



use lib 't';
use strict;
use TestDB qw($TEST_USERSEC $TEST_USERSEC_LOGIN);
use Bio::Genex::UserSec;
use Bio::Genex;
$::loaded_gs = 1;
my $i = 1;
print "ok ", $i++, "\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# testing a random attribute
my $c = new Bio::Genex::UserSec;
$c->login(555);
if ($c->login() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}
1;

# test fetch
$c = new Bio::Genex::UserSec(id=>$TEST_USERSEC);
$c->fetch();
if ($c->login() eq $TEST_USERSEC_LOGIN){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# test delayed_fetch
$c = new Bio::Genex::UserSec(id=>$TEST_USERSEC);
if (not defined $c->get_attribute('login')){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

if ($c->login() eq $TEST_USERSEC_LOGIN){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}


1;
