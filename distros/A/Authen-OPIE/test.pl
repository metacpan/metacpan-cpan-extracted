# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

print "OPIE must be set up on your box in order for this test to work\n";
print "You must be root in order to use the OPIE module (as root is the only one with permissions on the opiekey file)\n";
BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Authen::OPIE qw(opie_challenge opie_verify);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print "Login to test: ";
$login = <STDIN>;

chomp ($login);
$challenge = opie_challenge($login);
if (!defined($challenge)) {
	print "not ok 2: is opie set up on your box?\n";
	exit;
}
print "I challenge you [$login]: $challenge\n";
print "your response? ";
$response = <STDIN>;
chomp $response;

$result = opie_verify($login, $response);
if (!defined($result)) {
	print "not ok 3: is opie set up on your box?\n";
	exit;
}
if ($result == 0) {
	print "ok 3: response was verified (you passed)\n";
} else {
	print "ok 3: response was not verified (you failed, but opie worked)\n";
}
