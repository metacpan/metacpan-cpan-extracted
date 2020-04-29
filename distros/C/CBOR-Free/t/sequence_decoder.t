#!/usr/bin/env perl

package t::sequence_decoder;

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Exception;

use parent qw( Test::Class::Tiny );

use Data::Dumper;

use CBOR::Free::SequenceDecoder;

__PACKAGE__->runtests() if !caller;

sub T1_create_and_destroy {
    CBOR::Free::SequenceDecoder->new();

    ok 1;
}

sub T1_empty {
    my $decoder = CBOR::Free::SequenceDecoder->new();
    my $got = $decoder->give(q<>);

    is( $got, undef, 'give() returned undef when given empty' );
}

sub T1_undef {
    my $decoder = CBOR::Free::SequenceDecoder->new();
    my $got = $decoder->give(qq<\xf6>);

    is_deeply( $got, \undef, 'give() returned \undef when given CBOR null' );
}

sub T3_multiple {
    my $decoder = CBOR::Free::SequenceDecoder->new();
    my $got = $decoder->give(qq<\xf6\x80>);

    is_deeply( $got, \undef, 'give() returned first document' );
    is_deeply( $decoder->get(), \[], 'get() returns the next document' );

    is( $decoder->get(), undef, 'get() returned undef when there’s nothing more' );
}

sub T4_partial {
    my $decoder = CBOR::Free::SequenceDecoder->new();
    my $got = $decoder->give(qq<\x81>);

    is( $got, undef, 'give() returns incomplete if incomplete' );

    $got = $decoder->give(qq<\x41>);

    is( $got, undef, 'give() returns incomplete if (still) incomplete' );

    $got = $decoder->give(qq<a\xf6>);

    is_deeply( $got, \['a'], 'give() returned first document' );

    is_deeply( $decoder->get(), \undef, 'get() returned reference' );
}

1;
