######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Crypt::Passwd;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use Crypt::Passwd;

$| = 1;

eval { unix_std_crypt("foo", "bar"); };
if ($@ =~ /No standard crypt() defined/) {
	# Gratuitous success to keep number of tests constant
	print "ok 2\n";
} else {
	printf "%sok 2\n", (unix_std_crypt("foo", "bar") eq "ba4TuD1iozTxw") ? "" : "not ";
}

eval { unix_ext_crypt("foo", "bar"); };
if ($@ =~ /No extended crypt\(\) or crypt16\(\) defined/) {
	# Gratuitous success to keep number of tests constant
	print "ok 3\n";
} else {
	printf "%sok 3\n", (unix_ext_crypt("foo", "bar") eq "ba2sPhfOQ.cWwJyGvzMWSid.") ? "" : "not ";
}
