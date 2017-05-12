# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Crypt::xDBM_File;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use Crypt::Blowfish;

use SDBM_File;
use Fcntl;

tie %hash, 'Crypt::xDBM_File', 'Crypt::Blowfish', '01234567', 'SDBM_File', "/tmp/bob.blf", O_RDWR|O_CREAT, 0640;

$hash{'bob'} = "bob rules!";
$hash{'of'} = "yes";
$hash{'cult'} = "bob totally rules :)";
if (exists($hash{'of'})) {
	print "$hash{'of'} existed\n";
}
delete $hash{'of'};

print "key bob = $hash{'bob'}\n";
print "key cult = $hash{'cult'}\n";
untie %hash;

print "You should have a bob.xxx files in your tmp directory, an sdbm encrypted with blowfish\n";
