# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Spotter.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;



use lib 't';

# use TestDB qw($TEST_TREATMENTLEVEL $TEST_TREATMENTLEVEL_NAME);
use Bio::Genex::TreatmentLevel;
use Bio::Genex;
$loaded = 1;
my $i = 1;
print "ok ", $i++, "\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# testing a random attribute
my $p = Bio::Genex::TreatmentLevel->new();
$p->name(555);
if ($p->name() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

__END__
# no info in DB yet


# test fetch
$p = Bio::Genex::TreatmentLevel->new(id=>$TEST_TREATMENTLEVEL);
$p->fetch();
if ($p->name() eq $TEST_TREATMENTLEVEL_NAME){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# test delayed_fetch
$p = Bio::Genex::TreatmentLevel->new(id=>$TEST_TREATMENTLEVEL);
if (not defined $p->get_attribute('name')){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

if ($p->name() eq $TEST_TREATMENTLEVEL_NAME){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}


1;

