# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test;
BEGIN { plan tests => 10 };
use Authen::TacacsPlus;
ok(1);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# You will have to change these to suit yourself:
my $host = $ENV{AUTHEN_TACACSPLUS_TEST_HOST} || 'zulu.open.com.au';
my $key = $ENV{AUTHEN_TACACSPLUS_TEST_KEY} || 'mysecret';
my $timeout = 15;
my $port = 49;
my $username = $ENV{AUTHEN_TACACSPLUS_TEST_USERNAME} || 'mikem';
my $password = $ENV{AUTHEN_TACACSPLUS_TEST_PASSWORD} || 'fred';
# This is the CHAP encrypted password, including the challenge
# and identifier
my $chap_password = $ENV{AUTHEN_TACACSPLUS_TEST_CHAP_PASSWORD} 
    || 'djfhafghlkdlkfjasgljksgljkdsjsdfshdfgsdfkjglgh';

my $tac = new Authen::TacacsPlus(Host=>$host,
				 Key=>$key,
				 Timeout=>$timeout,
				 Port=>$port);
if ($tac)
{
    ok(1);
}
else
{
    foreach (2..10)
    {
	skip('Unable to complete tests because the test Tacacs server could not be contacted');
    }
    exit;
}


# test default type (ASCII), backwards compatible
ok($tac->authen($username, $password));
ok($tac->close() == 0);

my $tac = new Authen::TacacsPlus(Host=>$host,
				 Key=>$key,
				 Timeout=>$timeout,
				 Port=>$port);
ok($tac);

# test default PAP type
ok($tac->authen($username, $password, &Authen::TacacsPlus::TAC_PLUS_AUTHEN_TYPE_PAP));
ok($tac->close() == 0);

$tac = new Authen::TacacsPlus(Host=>$host,
				 Key=>$key,
				 Timeout=>$timeout,
				 Port=>$port);
ok($tac);

# test CHAP auth type
require Digest::MD5;
$chap_id = '5';
$chap_challenge = '1234567890123456';
# This is the CHAP response from the NAS. We will fake it here
# by calculating it in the same way th eNAS does:
$chap_response = Digest::MD5::md5($chap_id . $password . $chap_challenge);
$chap_string = $chap_id . $chap_challenge . $chap_response;

ok($tac->authen($username, $chap_string, &Authen::TacacsPlus::TAC_PLUS_AUTHEN_TYPE_CHAP));
ok($tac->close() == 0);

