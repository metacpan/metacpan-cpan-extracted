use strict;
use warnings;
use Test::More;
use Crypto::Exchange::Binance::Spot::API;

package Binance {
    use Moo;
    extends 'Crypto::Exchange::Binance::Spot::API';
    sub send {}
    sub json_response {{
        symbol => 'XRPGBP',
        price  => 1234,
    }}
};

my $binance = Binance->new;

my %pair = (coin => 'XRP', base => 'GBP');

my $data = $binance->prices(pair => \%pair);


is_deeply $data, {
    pair       => \%pair,
    last_price => 1234,
};

done_testing;
