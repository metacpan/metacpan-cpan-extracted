#!/usr/bin/perl

# Regression test for the V_ASN1_UTF8STRING branch of print_attribute:
# the original code copied utf8string->length bytes into a buffer of exactly
# utf8string->length bytes via strncpy, leaving no NUL terminator. Downstream
# callers (dump_certs_pkeys_bag, print_attribs) then ran strlen() on the
# result, reading past the end of the heap allocation. The byte count was
# passed to newSVpvn(), copying attacker-influenced heap bytes into the
# returned Perl scalar.
#
# certs/secretbag.p12 contains a UTF8STRING bag attribute at OID 1.2.3.4.5
# with value "MyCustomAttribute" (17 bytes, no embedded NUL). Pre-patch the
# scalar returned for this attribute contains "MyCustomAttribute" followed
# by trailing heap bytes; post-patch it is exactly "MyCustomAttribute".

use strict;
use warnings;

use Test::More;
use Crypt::OpenSSL::Guess qw(openssl_version find_openssl_prefix find_openssl_exec);

BEGIN { use_ok('Crypt::OpenSSL::PKCS12') }

my ($major) = openssl_version();
my $ssl_exec = find_openssl_exec(find_openssl_prefix());
my $ssl_version_string = `$ssl_exec version`;

SKIP: {
    skip 'Pre-3.0 OpenSSL does not support secret bags', 4 if $major lt '3.0';
    skip 'LibreSSL does not support secret bags', 4
        if $ssl_version_string =~ /LibreSSL/;

    my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_file('certs/secretbag.p12');
    ok($pkcs12, 'loaded secretbag.p12');

    # Poison the heap so any out-of-bounds read past the 17-byte UTF8STRING
    # allocation lands on non-zero bytes. Without this prep the heap byte at
    # offset 17 is frequently zero by luck and the bug fails to manifest.
    {
        my @junk;
        for my $sz (16, 17, 18, 20, 24, 32) {
            for (1..3000) {
                push @junk, ("\xAA" x $sz);
            }
        }
    }

    my $hash = eval { $pkcs12->info_as_hash('Password1') };
    is($@, '', 'info_as_hash() did not croak');
    ok(ref $hash eq 'HASH', 'info_as_hash() returned a hashref');

    # Locate the UTF8STRING attribute. secretbag.p12's secret bag carries a
    # custom attribute "1.2.3.4.5" whose value is ASN.1 UTF8STRING containing
    # "MyCustomAttribute" (17 bytes, no embedded NUL).
    #
    # Run several iterations: pre-patch, the missing NUL terminator means
    # strlen() walks past the allocation and the returned SV is longer than
    # 17 bytes on a significant fraction of runs (depends on which freed
    # chunk the allocator hands us). Post-patch, the explicit '\0' at
    # [length] guarantees strlen returns exactly 17 every time.
    my $expected = 'MyCustomAttribute';
    my $iterations = 50;
    my $bad = 0;
    my $first_leak;
    for my $i (1..$iterations) {
        my $h = $pkcs12->info_as_hash('Password1');
        my $attr = $h->{pkcs7_encrypted_data}[0]{bags}[0]{bag_attributes}{'1.2.3.4.5'};
        if ($attr ne $expected) {
            $bad++;
            $first_leak //= sprintf('iter %d: len=%d hex=%s',
                                    $i, length($attr), unpack('H*', $attr));
        }
    }
    is($bad, 0, "all $iterations iterations return exactly \"$expected\" — no OOB-read trailing bytes")
        or diag("first leak: $first_leak");
}

done_testing;
