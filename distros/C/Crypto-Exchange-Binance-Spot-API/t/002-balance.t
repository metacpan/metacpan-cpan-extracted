use strict;
use warnings;
use Test::More;
use Crypto::Exchange::Binance::Spot::API;

{package Binance;
    use Moo;
    extends 'Crypto::Exchange::Binance::Spot::API';
    sub send {}
    sub json_response {{
        balances => [
            {
                asset => 'XRP',
                free  => 1234,
                locked => 0,
            },
            {
                asset => 'GBP',
                free  => 888,
                locked => 999,
            },
            {
                asset => 'LDXRP',
                free  => 4567,
                locked => 0,
            },
            {
                asset => 'LDGBP',
                free  => 1888,
                locked => 0,
            },
        ],
    }}
}

my $binance = Binance->new;

my $data = $binance->balances;

is_deeply $data, {
    XRP => {
        coin      => 'XRP',
        available => 1234,
        in_order  => 0,
        staking   => 4567,
    },
    GBP => {
        coin      => 'GBP',
        available => 888,
        in_order  => 999,
        staking   => 1888,
    }
};

done_testing;
