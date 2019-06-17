#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

my %diagnostic = (
    Infinity => unpack("f>", "\x7f\x80\x00\x00"),
    NaN => unpack("f>", "\x7f\xc0\x00\x00"),
    '-Infinity' => unpack("f>", "\xff\x80\x00\x00"),
    undefined => undef,
);

diag explain \%ENV;

SKIP: {
    skip "Only for interactive testing!" if $ENV{'NONINTERACTIVE_TESTING'};

    my $tests_ar = eval {
        require HTTP::Tiny;
        require JSON;

        my $json = HTTP::Tiny->new()->get('https://raw.githubusercontent.com/cbor/test-vectors/master/appendix_a.json')->{'content'};

        JSON::decode_json($json);
    };

    skip "Failed to download test vectors: $@" if !$tests_ar;

    use_ok('CBOR::Free');

  CBOR_VALUE:
    for my $t (@$tests_ar) {

        # Tagged bignums, which CBOR::Free doesn’t support:
        next if $t->{'hex'} =~ m<\Ac[23]>i;

        # Perl can’t store -(~0).
        next if $t->{'hex'} eq '3bffffffffffffffff';

        # diag $t->{'hex'};

        my $cbor = pack 'H*', $t->{'hex'};

        my $expected;

        if (exists $t->{'decoded'}) {
            $expected = $t->{'decoded'};
        }
        elsif (my $diag = $t->{'diagnostic'}) {
            if (!exists $diagnostic{$diag}) {
                diag "Unknown diagnostic: “$diag”";
                next CBOR_VALUE;
            }

            $expected = $diagnostic{$diag};
        }

        my $decoded = CBOR::Free::decode($cbor);

        is_deeply( $decoded, $expected, "decode: $t->{'hex'}" );

        if ($t->{'roundtrip'}) {
            my $back2cbor = CBOR::Free::encode($expected);
            my $reparsed = CBOR::Free::decode($back2cbor);

            is_deeply(
                $reparsed,
                $expected,
                '… and it round-trips to back CBOR and out again',
            );

            # CBOR::Free always encodes floats to double (8-byte) precision.
            # So round-trip tests that expect full (4-byte) or half (2-byte)
            # precision won’t work.
            my $skip_yn = $t->{'hex'} =~ m<\Af[9a]>i;

            # undefined & null both become Perl undef, and we always
            # encode to null.
            $skip_yn ||= $t->{'hex'} eq 'f7';

            # We always encode to a binary string, so round-trip
            # tests that expect text won’t work.
            $skip_yn ||= $t->{'hex'} =~ m<\A[67]>;

            # Perl hashes don’t preserve order.
            $skip_yn ||= $t->{'hex'} =~ m<\A[ab]>;

            # Skip this one because of the nested strings.
            $skip_yn ||= $t->{'hex'} eq '826161a161626163';

            if (!$skip_yn) {
                my $encoded_hex = unpack 'H*', $back2cbor;

                is(
                    $encoded_hex,
                    $t->{'hex'},
                    '… and it round-trips back to CBOR as expected',
                );
            }
        }
    }
}

done_testing();
