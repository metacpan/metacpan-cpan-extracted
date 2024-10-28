#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Blockchain::Ethereum::ABI::Encoder;
use Blockchain::Ethereum::ABI::Decoder;

subtest "No params function" => sub {
    my $encoder = Blockchain::Ethereum::ABI::Encoder->new;
    my $encoded = $encoder->function('owner')->encode;

    is $encoded, '0x8da5cb5b', "correct encoding for no params function";
};

done_testing;
