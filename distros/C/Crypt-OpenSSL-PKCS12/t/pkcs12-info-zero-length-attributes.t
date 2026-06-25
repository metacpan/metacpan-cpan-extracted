#!/usr/bin/perl

# Regression test for the zero-length OCTET STRING / BIT STRING path of
# print_attribute() / get_hex(). Before the fix, get_hex() never wrote a NUL
# terminator, leaving *attribute uninitialised when length == 0. Downstream
# strlen() on an unterminated buffer is undefined behaviour.
#
# The fixture certs/zero-length-attrs.p12 carries two custom bag attributes:
#   1.2.3.100 → zero-length OCTET STRING  (ASN1_STRING_length() == 0)
#   1.2.3.101 → zero-length BIT STRING    (ASN1_STRING_length() == 0)
#
# info_as_hash() does not call PKCS12_verify_mac(), so the fixture's dummy MAC
# is never checked.

use strict;
use warnings;
use Test::More;
use File::Spec::Functions qw(catfile);

BEGIN { use_ok('Crypt::OpenSSL::PKCS12') }

my $fixture = catfile('certs', 'zero-length-attrs.p12');

SKIP: {
    skip "fixture $fixture not found", 5 unless -f $fixture;

    my $p12 = Crypt::OpenSSL::PKCS12->new_from_file($fixture);
    ok($p12, 'loaded zero-length-attrs.p12');

    my $hash = eval { $p12->info_as_hash('test') };
    is($@, '', 'info_as_hash() did not croak');
    ok(ref $hash eq 'HASH', 'info_as_hash() returned a hashref');

    # Locate bag_attributes in pkcs7_data bags
    my $attrs;
    OUTER: for my $section (@{ $hash->{pkcs7_data} // [] }) {
        for my $bag (@{ $section->{bags} // [] }) {
            if (exists $bag->{bag_attributes}{'1.2.3.100'}) {
                $attrs = $bag->{bag_attributes};
                last OUTER;
            }
        }
    }

    SKIP: {
        skip 'bag_attributes not found in pkcs7_data', 2 unless defined $attrs;

        is($attrs->{'1.2.3.100'}, '',
            'zero-length OCTET STRING attribute is empty string — get_hex() NUL-terminates');

        is($attrs->{'1.2.3.101'}, '',
            'zero-length BIT STRING attribute is empty string — get_hex() NUL-terminates');
    }
}

done_testing;
