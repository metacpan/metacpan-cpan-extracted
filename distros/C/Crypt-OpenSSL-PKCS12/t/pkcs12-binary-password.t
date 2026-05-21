#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;
use File::Spec::Functions qw(:ALL);
use Crypt::OpenSSL::Guess;

BEGIN { use_ok('Crypt::OpenSSL::PKCS12') }

my ($major, $minor, $patch) = openssl_version();

my $base = 'certs';
my $pass = 'testing';

my $certfile;
if ($major le "1.1") {
    $certfile = catdir($base, 'test_le_1.1.p12');
} else {
    $certfile = catdir($base, 'test.p12');
}

my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_file($certfile);
ok($pkcs12, 'PKCS12 object created');

# mac_ok returns true for the correct password
ok($pkcs12->mac_ok($pass), 'mac_ok returns true for correct password');

# Embedded NUL in password croaks for APIs that use strlen() internally.
# PKCS12_create() and PKCS12_newpass() cannot accept binary passwords.
{
    my $nul_pass = "pass\x00word";

    eval {
        $pkcs12->create(
            catdir($base, 'test-cert.pem'),
            catdir($base, 'test-key.pem'),
            $nul_pass,
            catdir($base, 'nul-out.p12'),
        );
    };
    like($@, qr/embedded NUL/i, 'create() croaks for NUL-containing password');
    unlink catdir($base, 'nul-out.p12');

    eval { $pkcs12->create_as_string(
        catdir($base, 'test-cert.pem'),
        catdir($base, 'test-key.pem'),
        $nul_pass,
    ) };
    like($@, qr/embedded NUL/i, 'create_as_string() croaks for NUL-containing password');

    SKIP: {
        if ($major =~ /^3\./) {
            skip("OpenSSL 3.x changepass not supported", 2);
        }
        eval { $pkcs12->changepass($nul_pass, 'newpass') };
        like($@, qr/embedded NUL/i, 'changepass() croaks for NUL-containing old password');

        eval { $pkcs12->changepass($pass, $nul_pass) };
        like($@, qr/embedded NUL/i, 'changepass() croaks for NUL-containing new password');
    }
}

# Regression guard for CVE-2026-8721 fix: SvPV (not SvPVbyte) must be used so
# that UTF-8 strings with codepoints > 255 reach OpenSSL without an encoding
# error. mac_ok will still croak on wrong password, but the error must come from
# PKCS12_verify_mac, not from Perl's "Wide character in subroutine entry".
{
    my $wide_pass = "\x{65E5}\x{672C}\x{8A9E}"; # 日本語
    eval { $pkcs12->mac_ok($wide_pass) };
    unlike($@, qr/Wide character/i,
        'mac_ok with wide-char password does not croak with encoding error');
    like($@, qr/PKCS12_verify_mac/i,
        'mac_ok with wide-char password croaks with PKCS12 error, not encoding error');
}
