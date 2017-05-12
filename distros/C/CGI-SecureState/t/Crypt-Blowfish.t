# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Crypt-Blowfish.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END { print "Bail out! Crypt::Blowfish, a required module for CGI::SecureState, ".
	    "could not be loaded.\n" unless $loaded;}
use Crypt::Blowfish;
$loaded = 1;
$test=1;
print "ok $test\n";

######################### End of black magic.

#test Crypt::Blowfish
$test++;
my $cipher = new Crypt::Blowfish (join("", map { sprintf("%.6f",rand()) } (1..3)));
my $words="Blah blah blah blah blah";
my $binstring=$words;

$binstring=~ s/(.{8})/$cipher->encrypt($1)/egs;
$binstring=~ s/(.{8})/$cipher->decrypt($1)/egs;
if ($binstring ne $words) { print "Bail out! Crypt::Blowfish, a required module for CGI::SecureState, does not work on your system!\n" }
else { print "ok $test\n" }
