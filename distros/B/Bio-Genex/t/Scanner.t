# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Scanner.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $::loaded_prot;}
use Carp;



use lib 't';
use strict;
use TestDB qw();
use Bio::Genex::Scanner;
use Bio::Genex;
$::loaded_prot = 1;
my $i = 1;
print "ok ", $i++, "\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# testing a random attribute
my $p = new Bio::Genex::Scanner;
$p->model_description(555);
if ($p->model_description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

__END__
# no info in DB yet


# test fetch
$p = new Bio::Genex::Scanner(id=>$TEST_SCANNER);
$p->fetch();
if ($p->model_description() eq $TEST_SCANNER_MODEL_DESCRIPTION){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# test delayed_fetch
$p = new Bio::Genex::Scanner(id=>$TEST_SCANNER);
if (not defined $p->get_attribute('model_description')){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

if ($p->model_description() eq $TEST_SCANNER_MODEL_DESCRIPTION){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}


1;
