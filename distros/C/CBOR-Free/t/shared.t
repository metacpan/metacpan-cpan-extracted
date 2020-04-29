#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Deep;

use parent 'Test::Class::Tiny';

use Data::Dumper;

use CBOR::Free;
use CBOR::Free::Decoder;
use CBOR::Free::SequenceDecoder;

__PACKAGE__->new()->runtests() if !caller;

sub T7_test_decoder {
    my $dec = CBOR::Free::Decoder->new();
    my $decode_cr = sub { $dec->decode($_[0]) };

    _test_shared($dec, $decode_cr);
}

sub T7_test_sequence_decoder {
    my $dec = CBOR::Free::SequenceDecoder->new();
    my $decode_cr = sub { ${ $dec->give($_[0]) } };

    _test_shared($dec, $decode_cr);
}

sub T1_against_cbor_xs {
    my ($self) = @_;

  SKIP: {
        skip "No CBOR::XS: $@", $self->num_tests() if !eval { require CBOR::XS };

        my $cxs = CBOR::XS->new();
        $cxs->allow_sharing();

        my $cxs_cbor = $cxs->encode( _create_data_struct() );
        is( _create_cbor(), $cxs_cbor, 'encode matches CBOR::XS' );
    }
}

sub _create_data_struct {
    my $plain_array = [];
    my $plain_hash = {};

    my $string = undef;
    my $string_r = \$string;

    return [ $plain_array, $plain_hash, $plain_array, $plain_hash, $string_r, $string_r ];
}

sub _create_cbor {
    return CBOR::Free::encode(
        _create_data_struct(),
        preserve_references => 1,
        scalar_references => 1,
    );
}

sub _test_shared {
    my ($dec, $decode_cr) = @_;

    my $out = _create_cbor();

    $dec->preserve_references();
    my $rt = $decode_cr->($out);

    cmp_deeply(
        $rt,
        [
            [],
            {},
            shallow( $rt->[0] ),
            shallow( $rt->[1] ),
            \undef,
            shallow( $rt->[4] ),
        ],
        ref($dec) . ": references are preserved",
    );

    my $rt2 = $decode_cr->($out);

    cmp_deeply(
        $rt2,
        [
            [],
            {},
            shallow( $rt2->[0] ),
            shallow( $rt2->[1] ),
            \undef,
            shallow( $rt2->[4] ),
        ],
        ref($dec) . ': references are preserved (again with the same object)',
    );

    my $got = $dec->preserve_references(0);
    cmp_deeply($got, bool(0), 'preserve_references() when setting falsy');

    my @w;
    my $rt3 = do {
        local $SIG{'__WARN__'} = sub { push @w, @_ };
        $decode_cr->($out);
    };

    cmp_deeply(
        $rt3,
        [
            [],
            {},
            0,
            1,
            \undef,
            2,
        ],
        ref($dec) . ': references are NOT preserved after disable',
    ) or diag explain $rt3;

    cmp_deeply(
        \@w,
        [
            re( qr<28> ),
            re( qr<28> ),
            re( qr<29> ),
            re( qr<29> ),
            re( qr<28> ),
            re( qr<29> ),
        ],
        'warnings are given about the shared tags',
    ) or diag explain \@w;

    # ----------------------------------------------------------------------

    # Flexes redundant-disable logic:
    $got = $dec->preserve_references(0);
    cmp_deeply($got, bool(0), 'preserve_references() return from redundant disable');

    @w = ();

    my $rt4 = do {
        local $SIG{'__WARN__'} = sub { push @w, @_ };
        $decode_cr->($out);
    };

    is_deeply( $rt4, $rt3, 'redo of non-preserve decode' ) or diag explain $rt4;
}
