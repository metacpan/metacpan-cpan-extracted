# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Crypt-OpenSSL-ECDSA.t'

#########################

use strict;
use warnings;

use Test::More tests => 25;
BEGIN { use_ok('Crypt::OpenSSL::ECDSA'); use_ok('Crypt::OpenSSL::EC');  };


my $fail = 0;
foreach my $constname (qw(
	ECDSA_F_ECDSA_CHECK ECDSA_F_ECDSA_DATA_NEW_METHOD ECDSA_F_ECDSA_DO_SIGN
	ECDSA_F_ECDSA_DO_VERIFY ECDSA_F_ECDSA_SIGN_SETUP ECDSA_R_BAD_SIGNATURE
	ECDSA_R_DATA_TOO_LARGE_FOR_KEY_SIZE ECDSA_R_ERR_EC_LIB
	ECDSA_R_MISSING_PARAMETERS ECDSA_R_NEED_NEW_SETUP_VALUES
	ECDSA_R_NON_FIPS_METHOD ECDSA_R_RANDOM_NUMBER_GENERATION_FAILED
	ECDSA_R_SIGNATURE_MALLOC_FAILED)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Crypt::OpenSSL::ECDSA macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $sig = new Crypt::OpenSSL::ECDSA::ECDSA_SIG;
ok($sig);
# test freeing
undef $sig;

#Crypt::OpenSSL::ECDSA::ECDSA_SIG_free($sig);

# Generate a random key (private and public) for our testing use
my $key = Crypt::OpenSSL::EC::EC_KEY::new();
ok($key);
my $nid = 415; # NID_X9_62_prime256v1
my $group = Crypt::OpenSSL::EC::EC_GROUP::new_by_curve_name($nid);
ok($group);
my $ret = Crypt::OpenSSL::EC::EC_KEY::set_group($key, $group);
ok($ret);
$ret = Crypt::OpenSSL::EC::EC_KEY::generate_key($key);
ok($ret);

# Testing signing and verifying
my $digest = "12345";
$sig = Crypt::OpenSSL::ECDSA::ECDSA_do_sign($digest, $key);
ok($sig);

# Test the r and s getters and setters
my $r = $sig->get_r();
ok($r);
my $s = $sig->get_s();
ok($s);
# Set them to some junk
$sig->set_r('1234');
$sig->set_s('1234');
# Should now fail verify
$ret = Crypt::OpenSSL::ECDSA::ECDSA_do_verify($digest, $sig, $key);
ok(!$ret);

# Put them back the way they were
$sig->set_r($r);
$sig->set_s($s);
# Verify should succeed
$ret = Crypt::OpenSSL::ECDSA::ECDSA_do_verify($digest, $sig, $key);
ok($ret);
undef $sig;

# Test a signature can be built from scratch
$sig = Crypt::OpenSSL::ECDSA::ECDSA_SIG->new();
ok($sig, 'Empty Crypt::OpenSSL::ECDSA::ECDSA_SIG object created');
eval { $sig->set_r($r); };
ok(!$@, 'R parameter set');
eval { $sig->set_s($s); };
ok(!$@, 'S parameter set');
$ret = Crypt::OpenSSL::ECDSA::ECDSA_do_verify($digest, $sig, $key);
ok($ret, 'built-from-scratch signature matches');
undef $sig;

# Testing signing and verifying with the _ex version
my $dummy = 0;
$sig = Crypt::OpenSSL::ECDSA::ECDSA_do_sign_ex($digest, \$dummy, \$dummy, $key);
ok($sig);
$ret = Crypt::OpenSSL::ECDSA::ECDSA_do_verify($digest, $sig, $key);
ok($ret);
undef $sig;

# Should be no errors so far
my $error = Crypt::OpenSSL::ECDSA::ERR_get_error();
print "its $error\n";
ok($error == 0);

# Test the ECDSA_METHOD calls
SKIP: {
	skip "ECDSA_METHOD calls not supported in OpenSSL < 1.0.2", 5, unless exists &Crypt::OpenSSL::ECDSA::ECDSA_METHOD_new;

      	my $method = Crypt::OpenSSL::ECDSA::ECDSA_OpenSSL();
	ok($method);
	Crypt::OpenSSL::ECDSA::ECDSA_set_default_method($method);
	ok(Crypt::OpenSSL::ECDSA::ECDSA_get_default_method());

	$ret = Crypt::OpenSSL::ECDSA::ECDSA_set_method($key, $method);
	ok($ret);

	$ret = Crypt::OpenSSL::ECDSA::ECDSA_size($key);
	ok($ret);

	$method = Crypt::OpenSSL::ECDSA::ECDSA_METHOD_new();
	ok($method);

	Crypt::OpenSSL::ECDSA::ECDSA_METHOD_set_flags($method, 0x00);

	Crypt::OpenSSL::ECDSA::ECDSA_METHOD_set_name($method, "fred");

	Crypt::OpenSSL::ECDSA::ECDSA_METHOD_free($method);
}

#$error = Crypt::OpenSSL::ECDSA::ERR_get_error();
#print "errno $error\n";
#my $string = Crypt::OpenSSL::ECDSA::ERR_error_string($error);
#print "err string $string\n";


