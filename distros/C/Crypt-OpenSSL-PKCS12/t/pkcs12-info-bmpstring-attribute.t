#!/usr/bin/perl

# Regression test for the V_ASN1_BMPSTRING branch of print_attribute.
#
# The original code did:
#     Renew(*attribute, length, char);          # length = BMP *byte* length
#     strncpy(*attribute, value, length);        # value = OPENSSL_uni2asc(...)
#
# For a normal BMPSTRING this is benign: uni2asc returns a NUL-terminated
# string roughly length/2 bytes long, so strncpy null-pads the oversized
# buffer and the result stays terminated. But for an *empty* BMPSTRING
# (length == 0) it degenerates: Perl's safesysrealloc treats a zero size as
# free-and-return-NULL, so Renew(*attribute, 0, char) frees the buffer and
# leaves *attribute NULL. Downstream callers (dump_certs_pkeys_bag /
# print_attribs) then run newSVpvn(attribute_value, strlen(attribute_value)),
# dereferencing NULL inside strlen(). Only info_as_hash() reaches this branch;
# info() passes a NULL hash, so *attribute stays NULL and print_attribute
# takes the BIO_printf branch. The fix sizes the buffer on strlen(value) + 1,
# which is never 0, and writes an explicit terminator: empty BMPSTRING -> "".
#
# Fixture certs/bmpstring-empty.p12 (password "Password1") is a certBag whose
# bag attribute at OID 1.2.3.4.6 is a zero-length ASN.1 BMPSTRING. It was
# generated with libcrypto: PKCS12_SAFEBAG_create_cert(test-cert.pem), then
# X509_ATTRIBUTE_set1_data(attr, V_ASN1_BMPSTRING, "", 0), packed via
# PKCS12_pack_p7data / PKCS12_add_safes with a SHA-256 MAC.

use strict;
use warnings;

use Test::More;
use Crypt::OpenSSL::Guess qw(openssl_version find_openssl_prefix find_openssl_exec);

BEGIN { use_ok('Crypt::OpenSSL::PKCS12') }

my ($major) = openssl_version();
my $ssl_exec = find_openssl_exec(find_openssl_prefix());
my $ssl_version_string = `$ssl_exec version`;

SKIP: {
    skip 'Pre-3.0 OpenSSL not exercised for this fixture', 4 if $major lt '3.0';
    skip 'LibreSSL not exercised for this fixture', 4
        if $ssl_version_string =~ /LibreSSL/;

    my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_file('certs/bmpstring-empty.p12');
    ok($pkcs12, 'loaded bmpstring-empty.p12');

    # Poison the heap before the run. This is not load-bearing: the defect is
    # a NULL dereference, which faults deterministically regardless of what
    # the surrounding heap holds. It is kept so the test also fails loudly if
    # this branch ever goes back to reading past a short allocation.
    {
        my @junk;
        for my $sz (8, 12, 16, 17, 24, 32) {
            push @junk, ("\xBB" x $sz) for 1 .. 3000;
        }
    }

    my $hash = eval { $pkcs12->info_as_hash('Password1') };
    is($@, '', 'info_as_hash() did not croak or crash');
    ok(ref $hash eq 'HASH', 'info_as_hash() returned a hashref');

    # Pre-patch: *attribute is NULL here, so strlen() faults and the process
    # SIGSEGVs before info_as_hash() can return. Post-patch: exactly the empty
    # string, on every iteration.
    my $expected = '';
    my $iterations = 50;
    my $bad = 0;
    my $first_bad;
    for my $i (1 .. $iterations) {
        my $h = $pkcs12->info_as_hash('Password1');
        my $attr = $h->{pkcs7_data}[0]{bags}[0]{bag_attributes}{'1.2.3.4.6'};
        $attr = '<undef>' unless defined $attr;
        if ($attr ne $expected) {
            $bad++;
            $first_bad //= sprintf('iter %d: len=%d hex=%s',
                                   $i, length($attr), unpack('H*', $attr));
        }
    }
    is($bad, 0, "all $iterations iterations return exactly the empty string")
        or diag("first mismatch: $first_bad");
}

done_testing;
