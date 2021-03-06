#!/usr/bin/perl

# MIT License
#
# Copyright (c) 2017 Lari Taskula  <lari@taskula.fi>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

use strict;
use warnings;

use Test::MockModule;
use Test::More tests => 10;
use Test::Warn;

use Binance::API;

# Mock Binance::API::Request::_exec in order to avoid executing a real http
# request. Instead return whatever we pass to the api_result method.
my $mock = Test::MockModule->new('Binance::API::Request');
sub api_result {
    my $expected_result = shift;
    $mock->redefine('_exec', sub {
        return $expected_result;
    });
}

my $api = Binance::API->new();

subtest 'new() tests' => sub {
    plan tests => 4;

    ok(Binance::API->can('new'), 'method new() available');

    my $api = Binance::API->new();
    is(ref($api), 'Binance::API', 'new() returns an instance of Binance::API');

    $api = Binance::API->new(
        apiKey     => 'key',
        secretKey  => 'secret',
        recvWindow => 10000,
    );

    is(ref($api->{'ua'}),     'Binance::API::Request', 'Binance::API::Request');
    is(ref($api->{'logger'}), 'Binance::API::Logger',  'Binance::API::Logger');
};

subtest 'aggregate_trades() tests' => sub {
    plan tests => 5;

    ok(Binance::API->can('aggregate_trades'), 'method aggregate_trades() '.
       'available');

    api_result([
        { 'T' => 1 }
    ]);

    eval { $api->aggregate_trades };
    is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
       .'when missing a parameter');
    is($@->parameters->[0], 'symbol', 'Missing parameter "symbol"');

    my $aggTrades = $api->aggregate_trades( symbol => 'ETHBTC' );
    ok(defined $aggTrades, 'Requested aggregate trades');
    ok($aggTrades->[0]->{'T'} > 0, 'Got a successful response');
};

subtest 'all_book_tickers() tests' => sub {
    plan tests => 3;

    ok(Binance::API->can('all_book_tickers'), 'method all_book_tickers() '
       .'available');

    api_result([
        { 'symbol' => 'ETHBTC' }
    ]);

    my $all_book_tickers = $api->all_book_tickers;
    ok(defined $all_book_tickers, 'Requested all_book_tickers');
    ok(defined $all_book_tickers->[0]->{'symbol'}, 'Got a successful response');
};

subtest 'ticker_price() tests' => sub {
    plan tests => 6;

    ok(Binance::API->can('ticker_price'), 'method ticker_price() '
       .'available');

    api_result([
        { 'symbol' => 'ETHBTC' }
    ]);

    my $all_prices = $api->ticker_price;
    ok(defined $all_prices, 'Requested all ticker_price');
    ok(defined $all_prices->[0]->{'symbol'}, 'Got a successful response');
    ok($all_prices > 0, 'Got multiple ticker prices');

    api_result(
        { 'symbol' => 'ETHBTC' }
    );

    my $one_price = $api->ticker_price( symbol => 'ETHBTC' );
    ok(defined $one_price, 'Requested one ticker_price');
    is($one_price->{'symbol'}, 'ETHBTC', 'Got a successful response');
};

subtest 'depth() tests' => sub {
    plan tests => 6;

    ok(Binance::API->can('depth'), 'method depth() available');

    api_result([
        { 'symbol' => 'ETHBTC' }
    ]);

    eval { $api->depth };
    is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
       .'when missing a parameter');
    is($@->parameters->[0], 'symbol', 'Missing parameter "symbol"');

    api_result(
        { 'asks' => [0,1], 'bids' => [0,1] }
    );

    my $depth = $api->depth( symbol => 'ETHBTC' );
    ok(defined $depth, 'Requested depth');
    ok(@{$depth->{'asks'}} > 0 , 'Depth has returned some asks');
    ok(@{$depth->{'bids'}} > 0 , 'Depth has returned some bids');
};

subtest 'klines() tests' => sub {
    plan tests => 7;

    ok(Binance::API->can('klines'), 'method klines() available');

    api_result([
        [ 1 ]
    ]);

    eval { $api->klines };
    is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
       .'when missing a parameter');
    is($@->parameters->[0], 'symbol', 'Missing parameter "symbol"');

    eval { $api->klines( symbol => 'ETHBTC' ) };
    is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
       .'when missing a parameter');
    is($@->parameters->[0], 'interval', 'Missing parameter "interval"');

    my $klines = $api->klines( symbol => 'ETHBTC', interval => '1M' );
    ok(defined $klines, 'Requested klines');
    ok($klines->[0]->[0] > 0, 'Got a successful response');
};

subtest 'order() tests' => sub {
    plan tests => 13;

    ok(Binance::API->can('order'), 'method order() available');

    api_result([
        { 'symbol' => 'ETHBTC' }
    ]);

    eval { $api->order_test( symbol => 'ETHBTC', side => 'SELL' ) };
    is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
       .'when missing a parameter');
    is($@->parameters->[0], 'type', 'Missing parameter "type"');

    eval { $api->order_test( type => 'NONEXISTENT' ) };
    is(ref($@), 'Binance::Exception::Parameter::BadValue', 'Exception thrown '
       .'when given a bad parameter');
    is($@->parameters->[0], 'type', 'Missing parameter "type"');
    ok($@->format, 'Format describes what is expected');

    subtest 'type: LIMIT' => sub {
        eval { $api->order_test( type => 'LIMIT' ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'symbol', 'Missing parameter "symbol"');

        eval { $api->order_test( type => 'LIMIT', symbol => 'ETHBTC' ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'side', 'Missing parameter "side"');

        eval { $api->order_test(
            type => 'LIMIT', symbol => 'ETHBTC', side => 'SELL'
        ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'timeInForce', 'Missing parameter "timeInForce"');

        eval { $api->order_test(
            type => 'LIMIT', symbol => 'ETHBTC', side => 'SELL',
            timeInForce => 1
        ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'quantity', 'Missing parameter "quantity"');

        eval { $api->order_test(
            type => 'LIMIT', symbol => 'ETHBTC', side => 'SELL',
            timeInForce => 1, quantity => 1
        ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'price', 'Missing parameter "price"');
    };

    subtest 'type: MARKET' => sub {
        eval { $api->order_test(
            type => 'MARKET', symbol => 'ETHBTC', side => 'SELL'
        ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'quantity', 'Missing parameter "quantity" ...');
        is($@->parameters->[1], 'quoteOrderQty', '... or missing parameter "quoteOrderQty"');
    };

    subtest 'type: STOP_LOSS' => sub {
        eval { $api->order_test( type => 'STOP_LOSS' ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'symbol', 'Missing parameter "symbol"');

        eval { $api->order_test( type => 'STOP_LOSS', symbol => 'ETHBTC' ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'side', 'Missing parameter "side"');

        eval { $api->order_test(
            type => 'STOP_LOSS', symbol => 'ETHBTC', side => 'SELL'
        ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'quantity', 'Missing parameter "quantity"');

        eval { $api->order_test(
            type => 'STOP_LOSS', symbol => 'ETHBTC', side => 'SELL',
            quantity => 1
        ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'stopPrice', 'Missing parameter "stopPrice"');
    };

    subtest 'type: STOP_LOSS_LIMIT' => sub {
        eval { $api->order_test( type => 'STOP_LOSS_LIMIT' ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'symbol', 'Missing parameter "symbol"');

        eval { $api->order_test( type => 'STOP_LOSS_LIMIT', symbol => 'ETHBTC' ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'side', 'Missing parameter "side"');

        eval { $api->order_test(
            type => 'STOP_LOSS_LIMIT', symbol => 'ETHBTC', side => 'SELL'
        ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'timeInForce', 'Missing parameter "timeInForce"');

        eval { $api->order_test(
            type => 'STOP_LOSS_LIMIT', symbol => 'ETHBTC', side => 'SELL',
            timeInForce => 1
        ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'quantity', 'Missing parameter "quantity"');

        eval { $api->order_test(
            type => 'STOP_LOSS_LIMIT', symbol => 'ETHBTC', side => 'SELL',
            timeInForce => 1, quantity => 1
        ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'price', 'Missing parameter "price"');

        eval { $api->order_test(
            type => 'STOP_LOSS_LIMIT', symbol => 'ETHBTC', side => 'SELL',
            timeInForce => 1, quantity => 1, price => 0,
        ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'stopPrice', 'Missing parameter "stopPrice"');
    };

    subtest 'type: TAKE_PROFIT' => sub {
        eval { $api->order_test( type => 'TAKE_PROFIT' ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'symbol', 'Missing parameter "symbol"');

        eval { $api->order_test( type => 'TAKE_PROFIT', symbol => 'ETHBTC' ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'side', 'Missing parameter "side"');

        eval { $api->order_test(
            type => 'TAKE_PROFIT', symbol => 'ETHBTC', side => 'SELL'
        ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'quantity', 'Missing parameter "quantity"');

        eval { $api->order_test(
            type => 'TAKE_PROFIT', symbol => 'ETHBTC', side => 'SELL',
            quantity => 1
        ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'stopPrice', 'Missing parameter "stopPrice"');
    };

    subtest 'type: TAKE_PROFIT_LIMIT' => sub {
        eval { $api->order_test( type => 'TAKE_PROFIT_LIMIT' ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'symbol', 'Missing parameter "symbol"');

        eval { $api->order_test( type => 'TAKE_PROFIT_LIMIT', symbol => 'ETHBTC' ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'side', 'Missing parameter "side"');

        eval { $api->order_test(
            type => 'TAKE_PROFIT_LIMIT', symbol => 'ETHBTC', side => 'SELL'
        ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'timeInForce', 'Missing parameter "timeInForce"');

        eval { $api->order_test(
            type => 'TAKE_PROFIT_LIMIT', symbol => 'ETHBTC', side => 'SELL',
            timeInForce => 1
        ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'quantity', 'Missing parameter "quantity"');

        eval { $api->order_test(
            type => 'TAKE_PROFIT_LIMIT', symbol => 'ETHBTC', side => 'SELL',
            timeInForce => 1, quantity => 1
        ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'price', 'Missing parameter "price"');

        eval { $api->order_test(
            type => 'TAKE_PROFIT_LIMIT', symbol => 'ETHBTC', side => 'SELL',
            timeInForce => 1, quantity => 1, price => 0,
        ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'stopPrice', 'Missing parameter "stopPrice"');
    };

    subtest 'type: LIMIT_MAKER' => sub {
        eval { $api->order_test( type => 'LIMIT_MAKER' ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'symbol', 'Missing parameter "symbol"');

        eval { $api->order_test( type => 'LIMIT_MAKER', symbol => 'ETHBTC' ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'side', 'Missing parameter "side"');

        eval { $api->order_test(
            type => 'LIMIT_MAKER', symbol => 'ETHBTC', side => 'SELL'
        ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'quantity', 'Missing parameter "quantity"');

        eval { $api->order_test(
            type => 'LIMIT_MAKER', symbol => 'ETHBTC', side => 'SELL',
            timeInForce => 1, quantity => 1
        ) };
        is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
           .'when missing a parameter');
        is($@->parameters->[0], 'price', 'Missing parameter "price"');
    };
};

subtest 'ping() tests' => sub {
    plan tests => 2;

    ok(Binance::API->can('ping'), 'method ping() available');

    api_result({ });

    ok($api->ping('/api/v1/ping', 'get'), 'Pinging Binance server');
};

subtest 'ticker() tests' => sub {
    plan tests => 5;

    ok(Binance::API->can('ticker'), 'method ticker() available');

    api_result(
        { 'openTime' => 1 }
    );

    eval { $api->klines };
    is(ref($@), 'Binance::Exception::Parameter::Required', 'Exception thrown '
       .'when missing a parameter');
    is($@->parameters->[0], 'symbol', 'Missing parameter "symbol"');

    my $ticker = $api->ticker( symbol => 'ETHBTC' );
    ok(defined $ticker, 'Requested ticker');
    ok($ticker->{'openTime'} > 0, 'Got a successful response');
};

subtest 'time() tests' => sub {
    plan tests => 2;

    ok(Binance::API->can('time'), 'method time() available');

    api_result({ 'serverTime' => 1513415733605 });

    ok($api->time() > 1513415733604, 'Binance server time');
};
