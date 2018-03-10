#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use CryptoCurrency::Catalog;

my $cat = CryptoCurrency::Catalog->new;

subtest "by_code" => sub {
    is_deeply($cat->by_code("btc"), {code=>"BTC", name=>"Bitcoin", safename=>"bitcoin"});
    dies_ok { $cat->by_code("FOO") };
};

subtest "by_ticker" => sub {
    is_deeply($cat->by_ticker("btc"), {code=>"BTC", name=>"Bitcoin", safename=>"bitcoin"});
};

subtest "by_name" => sub {
    is_deeply($cat->by_name("Ethereum"), {code=>"ETH", name=>"Ethereum", safename=>"ethereum"});
    is_deeply($cat->by_name("ethereum"), {code=>"ETH", name=>"Ethereum", safename=>"ethereum"});
    dies_ok { $cat->by_name("foo bar") };
};

subtest "by_safename" => sub {
    is_deeply($cat->by_safename("ethereum"), {code=>"ETH", name=>"Ethereum", safename=>"ethereum"});
    dies_ok { $cat->by_safename("foo") };
};

subtest "by_slug" => sub {
    is_deeply($cat->by_slug("ETHEREUM"), {code=>"ETH", name=>"Ethereum", safename=>"ethereum"});
};

subtest "all_codes" => sub {
    my @codes = $cat->all_codes;
    ok(@codes);
};

subtest "all_data" => sub {
    my @all_data = $cat->all_data;
    ok(@all_data);
};

DONE_TESTING:
done_testing;
