#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 17;
use File::Spec::Functions qw(:ALL);
use Data::Dumper;
use Crypt::OpenSSL::Guess;

BEGIN { use_ok('Crypt::OpenSSL::PKCS12') };

my $base   = 'certs';
my $pass   = 'testing';

my ($major, $minor, $patch) = openssl_version();

my $certfile;
if ($major le "1.1" )  {
    $certfile = catdir($base, 'test_le_1.1.p12');
} else {
    $certfile = catdir($base, 'test.p12');
}

diag("Attempting to read certificate from $certfile");

my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_file($certfile);

ok($pkcs12, 'PKCS object created');

my $pemcert = $pkcs12->certificate($pass);

ok($pemcert, 'PEM certificate created');

my $cacert = $pkcs12->ca_certificate($pass);

ok($cacert, 'CA certificate created');

my $pemkey = $pkcs12->private_key($pass);

ok($pemkey, 'Asserting PEM key');

ok($pkcs12->mac_ok($pass), 'Asserting mac');

ok($pkcs12->as_string, 'Asserting PKCS12 as string');

SKIP: {
    # PKCS12_newpass() is fundamentally broken for PBES2-encrypted PKCS12
    # files (the default since OpenSSL 1.1/3.x): confirmed upstream at
    # https://github.com/openssl/openssl/issues/19092. It also fails
    # differently on 3.0 (ASN1 parse error) vs 3.5+/4.x (unknown pbe
    # algorithm). Only OpenSSL 1.x is confirmed to work; see #62.
    if ($major !~ /^1\./) {
        skip("changepass unsupported on OpenSSL $major (see #62)", 3);
    } else {
        # try changing the password
        local $@;
        my $changed = eval { $pkcs12->changepass($pass, 'foo') };
        ok($changed, 'Changing password') or diag($@ || 'changepass returned false');

        SKIP: {
            skip('changepass failed, skipping dependent checks', 2) unless $changed;

            local $@;
            my $verified = eval { $pkcs12->mac_ok('foo') };
            ok($verified, 'Reasserting mac') or diag($@ || 'mac_ok returned false');

            local $@;
            my $changed_again = eval { $pkcs12->changepass('foo', $pass) };
            ok($changed_again, 'Changing password again') or diag($@ || 'changepass returned false');
        }
    }
}

# Try creating a PKCS12 file.
my $outfile = catdir($base, 'out.p12');

ok($pkcs12->create(
	catdir($base, 'test-cert.pem'),
	catdir($base, 'test-key.pem'),
	$pass,
	$outfile,
	'Friendly Name'
), 'Testing create based on PKCS12');

ok(-f $outfile);

my $created = Crypt::OpenSSL::PKCS12->new_from_file($outfile);

ok($created);

ok($created->mac_ok($pass), 'Reasserting new mac');

unlink $outfile;

my $pksc12_data = $pkcs12->create_as_string(
	catdir($base, 'test-cert.pem'),
	catdir($base, 'test-key.pem'),
	$pass,
	"Friendly Name"
);

ok($pksc12_data);

$created = Crypt::OpenSSL::PKCS12->new_from_string($pksc12_data);

ok($created);

ok($created->mac_ok($pass));
