# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Crypt.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
# XXX use Test::More tests => 2;

# XXX #BEGIN { u s e _ o k ('Crypt::Lite') };
BEGIN { use_ok('Crypt::Lite') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $skip_tests = 0;
unless (eval "require MD5") {
	#print "No MD5 module.\n";
	$skip_tests = 1;
}

my $c;
my $enc = my $dec = '';

$c = Crypt::Lite->new(debug => 0, encoding => 'hex8') unless $skip_tests;

unless ($skip_tests) {
	$enc = $c->encrypt('plain text to encrypt', 'mysecret');
	$dec = $c->decrypt($enc, 'mysecret');
}
ok(($dec eq 'plain text to encrypt' or $skip_tests), 'Encryption / Decryption');


$dec = $c->decrypt($enc, 'wrongpassword') unless $skip_tests;
ok(($dec eq '' or $skip_tests), 'Double check. skip_tests: ' . $skip_tests);

sleep 1;
