# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {print "1..1\n";}
END {print "not ok 1\n" unless $loaded;}
use CookBookB::ListOfStruct;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$a = CookBookB::ListOfStruct->new;
{
  my $b = CookBookB::ListOfStruct->new;
  $b->fill( 1.4, 1.5 );
  $a->push($b);

  # $b goes out of scope now--but doesn't get destroyed, because $a
  # has a reference to it.
}

$a->fill( 1.2, 1.3 );
$a->foo;

# now $a goes out of scope, so it is destroyed.  When $a is destroyed it
# releases its reference to $b, so then $b is destroyed.
