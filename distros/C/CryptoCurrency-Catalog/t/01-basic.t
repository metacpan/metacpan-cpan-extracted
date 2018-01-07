#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use CryptoCurrency::Catalog;

my $cat = CryptoCurrency::Catalog->new;

subtest "by_symbol" => sub {
    is_deeply($cat->by_symbol("btc"), {symbol=>"BTC", name=>"Bitcoin", safename=>"bitcoin"});
    dies_ok { $cat->by_symbol("FOO") };
};

subtest "by_ticker" => sub {
    is_deeply($cat->by_ticker("btc"), {symbol=>"BTC", name=>"Bitcoin", safename=>"bitcoin"});
};

subtest "by_name" => sub {
    is_deeply($cat->by_name("Ethereum"), {symbol=>"ETH", name=>"Ethereum", safename=>"ethereum"});
    dies_ok { $cat->by_name("ethereum") };
};

subtest "by_safename" => sub {
    is_deeply($cat->by_safename("ethereum"), {symbol=>"ETH", name=>"Ethereum", safename=>"ethereum"});
    dies_ok { $cat->by_safename("foo") };
};

subtest "by_slug" => sub {
    is_deeply($cat->by_slug("ETHEREUM"), {symbol=>"ETH", name=>"Ethereum", safename=>"ethereum"});
};

subtest "all_symbols" => sub {
    my @symbols = $cat->all_symbols;
    ok(@symbols);
};

subtest "all_data" => sub {
    my @all_data = $cat->all_data;
    ok(@all_data);
};

DONE_TESTING:
done_testing;
