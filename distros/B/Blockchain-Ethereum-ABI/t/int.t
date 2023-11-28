#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Blockchain::Ethereum::ABI::Encoder;
use Blockchain::Ethereum::ABI::Decoder;

subtest "Negative" => sub {
    my $encoder = Blockchain::Ethereum::ABI::Encoder->new;
    $encoder->function('foo')->append('int256' => -100);
    my $encoded = $encoder->encode;

    is $encoded, '0x4c970b2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9c';

    my $decoder = Blockchain::Ethereum::ABI::Decoder->new;

    my $decoded = $decoder->append('uint256')->decode('0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9c');
    is $decoded->[0], -100;
};

done_testing;

