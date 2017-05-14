# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Citation.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $::loaded_cit;}
use Carp;


use lib 't';
use strict;
use TestDB qw($YEAST_CITATION $YEAST_CITATION_AUTHORS);
use Bio::Genex::Citation;
use Bio::Genex;
$::loaded_cit = 1;
my $i = 1;
print "ok ", $i++, "\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# testing a random attribute
my $c = new Bio::Genex::Citation;
$c->authors(555);
if ($c->authors() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# test fetch
$c = new Bio::Genex::Citation(id=>$YEAST_CITATION);
$c->fetch();
if ($c->authors() eq $YEAST_CITATION_AUTHORS){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# test delayed_fetch
$c = new Bio::Genex::Citation(id=>$YEAST_CITATION);
if (not defined $c->get_attribute('authors')){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

if ($c->authors() eq $YEAST_CITATION_AUTHORS){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}


1;
