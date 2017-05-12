# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Acme::Don't;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

don't { print "not "   };  
   do { print "ok 2\n" };

print "not " if don't { my $str = "cat"; $str =~ /[aeiou]/ };
print "ok 3\n";

don't { print "not " } || print "ok 4\n";

my $count = 10;
don't {
	print "not "
} while $count--;
print "ok 5\n";
