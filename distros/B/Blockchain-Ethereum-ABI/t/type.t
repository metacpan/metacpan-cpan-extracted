#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Blockchain::Ethereum::ABI::Type;

subtest "Int" => sub {
    my $data = "0x0000000000000000000000000000000000000000000000000858898f93629000";
    my $type = Blockchain::Ethereum::ABI::Type->new(
        signature => 'uint256',
        data      => $data
    );
    is $type->isa('Blockchain::Ethereum::ABI::Type::Int'), 1;
};

done_testing;
