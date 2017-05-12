#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;

use Crypt::NSS config_dir => "db";

# Find cert
my $cert = Crypt::NSS::PKCS11->find_cert_by_nickname("127.0.0.1");
ok($cert);
isa_ok($cert, "Crypt::NSS::Certificate");

# Verify hostname
my $valid = 1;
lives_ok {
    $valid = $cert->verify_hostname("localhost");
};
ok(!$valid);

$valid = 0;
$valid = $cert->verify_hostname("127.0.0.1");
ok($valid);

is($cert->get_validity_for_datetime(2008, 10, 01), 0);

is($cert->issuer, "CN=Test CA,O=Crypt-NSS,ST=Stockholm,C=SE");
is($cert->subject, "CN=127.0.0.1,O=Crypt-NSS,ST=Stockholm,C=SE");
ok(!defined $cert->email_address);
