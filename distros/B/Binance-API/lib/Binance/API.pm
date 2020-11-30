package Binance::API;

# MIT License
#
# Copyright (c) 2018
# Lari Taskula  <lari@taskula.fi>
# Filip La Gre <tutenhamond@gmail.com>
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

use Carp;
use Scalar::Util qw( blessed );

use Binance::API::Logger;
use Binance::API::Request;

use Binance::Exception::Parameter::BadValue;
use Binance::Exception::Parameter::Required;

our $VERSION = '1.05';

=head1 NAME

Binance::API -- Perl implementation for Binance API

=head1 DESCRIPTION

This module provides a Perl implementation for Binance API

Binance API documentation: C<https://github.com/binance-exchange/binance-official-api-docs/blob/master/rest-api.md>.

ENUM definitions:
https://github.com/binance-exchange/binance-official-api-docs/blob/master/rest-api.md#enum-definitions

=head1 SYNOPSIS

    use Binance::API;

    my $api = Binance::API->new(
        apiKey    => 'my_api_key',
        secretKey => 'my_secret_key',
    );

    my $ticker = $api->ticker( symbol => 'ETHBTC' );

=head1 METHODS

=cut

=head2 new

    my $api = Binance::API->new(
        apiKey    => 'my_api_key',
        secretKey => 'my_secret_key',
    );

Instantiates a new C<Binance::API> object

B<PARAMETERS>

=over

=item apiKey

[OPTIONAL] Your Binance API key.

=item secretKey

[OPTIONAL] Your Binance API secret key.

=item recvWindow

[OPTIONAL] Number of milliseconds the request is valid for. Applies only in
signed requests.

=item logger

[OPTIONAL] See L<Binance::API::Logger/new>

=back

B<RETURNS>

A C<Binance::API> object.

=cut

sub new {
    my ($class, %params) = @_;

    my $logger = Binance::API::Logger->new($params{logger});

    my $ua = Binance::API::Request->new(
        apiKey     => $params{apiKey},
        secretKey  => $params{secretKey},
        recvWindow => $params{recvWindow},
        logger     => $logger,
    );

    my $self = {
        ua         => $ua,
        logger     => $logger,
    };

    bless $self, $class;
}

=head2 ping

    $api->ping();

Test connectivity to the Rest API

B<PARAMETERS>

=over

=item Takes no parameters.

=back


B<RETURNS>
1 if successful, otherwise 0

=cut

sub ping {
    return keys %{$_[0]->ua->get('/api/v1/ping')} == 0 ? 1 : 0;
}

=head2 time

    $api->time();

Test connectivity to the Rest API and get the current server time.

B<PARAMETERS>

=over

=item Takes no parameters.

=back

B<RETURNS>
    Server (epoch) time in milliseconds

=cut

sub time {
    my $self = shift;

    my $time = $self->ua->get('/api/v1/time');
    return exists $time->{serverTime} ? $time->{serverTime} : 0;
}

=head2 exchange_info

    $api->exchange_info();

Current exchange trading rules and symbol information.

B<PARAMETERS>

=over

=item Takes no parameters.

=back

B<RETURNS>
    A HASHref

    {
      "timezone": "UTC",
      "serverTime": 1508631584636,
      "rateLimits": [{
          "rateLimitType": "REQUESTS",
          "interval": "MINUTE",
          "limit": 1200
        },
        {
          "rateLimitType": "ORDERS",
          "interval": "SECOND",
          "limit": 10
        },
        {
          "rateLimitType": "ORDERS",
          "interval": "DAY",
          "limit": 100000
        }
      ],
      "exchangeFilters": [],
      "symbols": [{
        "symbol": "ETHBTC",
        "status": "TRADING",
        "baseAsset": "ETH",
        "baseAssetPrecision": 8,
        "quoteAsset": "BTC",
        "quotePrecision": 8,
        "orderTypes": ["LIMIT", "MARKET"],
        "icebergAllowed": false,
        "filters": [{
          "filterType": "PRICE_FILTER",
          "minPrice": "0.00000100",
          "maxPrice": "100000.00000000",
          "tickSize": "0.00000100"
        }, {
          "filterType": "LOT_SIZE",
          "minQty": "0.00100000",
          "maxQty": "100000.00000000",
          "stepSize": "0.00100000"
        }, {
          "filterType": "MIN_NOTIONAL",
          "minNotional": "0.00100000"
        }]
      }]
    }

=cut

sub exchange_info {
    return $_[0]->ua->get('/api/v1/ticker/exchangeInfo');
}

=head2 depth

    $api->depth( symbol => 'ETHBTC' );

B<PARAMETERS>

=over

=item symbol

[REQUIRED] Symbol, for example C<ETHBTC>.

=item limit

[OPTIONAL] Default 100; max 100.

=back

B<RETURNS>
    A HASHref

    {
      "lastUpdateId": 1027024,
      "bids": [
        [
          "4.00000000",     // PRICE
          "431.00000000",   // QTY
          []                // Can be ignored
        ]
      ],
      "asks": [
        [
          "4.00000200",
          "12.00000000",
          []
        ]
      ]
    }

=cut

sub depth {
    my ($self, %params) = @_;

    unless ($params{'symbol'}) {
        $self->log->error('Parameter "symbol" required');
        Binance::Exception::Parameter::Required->throw(
            error => 'Parameter "symbol" required',
            parameters => ['symbol']
        );
    }

    my $query = {
        symbol => $params{'symbol'},
        limit  => $params{'limit'},
    };

    return $self->ua->get('/api/v1/depth', { query => $query } );
}

=head2 trades

    $api->trades();

Get recent trades (up to last 500).

B<PARAMETERS>

=over

=item symbol

[REQUIRED] Symbol, for example C<ETHBTC>.

=item limit

[OPTIONAL] Default 500; max 500.

=back

B<RETURNS>
    An ARRAYref of HASHrefs

    [
      {
        "id": 28457,
        "price": "4.00000100",
        "qty": "12.00000000",
        "time": 1499865549590,
        "isBuyerMaker": true,
        "isBestMatch": true
      }
    ]

=cut

sub trades {
    my ($self, %params) = @_;

    unless ($params{'symbol'}) {
        $self->log->error('Parameter "symbol" required');
        Binance::Exception::Parameter::Required->throw(
            error => 'Parameter "symbol" required',
            parameters => ['symbol']
        );
    }

    my $query = {
        symbol    => $params{'symbol'},
        limit     => $params{'limit'},
    };

    return $self->ua->get('/api/v1/trades', { query => $query } );
}

=head2 historical_trades

$api->historical_trades();

Get older trades.

B<PARAMETERS>

=over

=item symbol

[REQUIRED] Symbol, for example C<ETHBTC>.

=item limit

[OPTIONAL] Default 500; max 500.

=item fromId

[OPTIONAL] TradeId to fetch from. Default gets most recent trades.

=back

B<RETURNS>
    An ARRAYref of HASHrefs

    [
      {
        "id": 28457,
        "price": "4.00000100",
        "qty": "12.00000000",
        "time": 1499865549590,
        "isBuyerMaker": true,
        "isBestMatch": true
      }
    ]

=cut

sub historical_trades {
    my ($self, %params) = @_;

    unless ($params{'symbol'}) {
        $self->log->error('Parameter "symbol" required');
        Binance::Exception::Parameter::Required->throw(
            error => 'Parameter "symbol" required',
            parameters => ['symbol']
        );
    }

    my $query = {
        symbol    => $params{'symbol'},
        limit     => $params{'limit'},
        fromId    => $params{'fromId'},
    };

    return $self->ua->get('/api/v1/historicalTrades', { query => $query } );
}

=head2 aggregate_trades

    $api->aggregate_trades( symbol => 'ETHBTC' );

Gets compressed, aggregate trades. Trades that fill at the time, from the same
order, with the same price will have the quantity aggregated.

B<PARAMETERS>

=over

=item symbol

[REQUIRED] Symbol, for example C<ETHBTC>.

=item fromId

[OPTIONAL] ID to get aggregate trades from INCLUSIVE.


=item startTime

[OPTIONAL] timestamp in ms to get aggregate trades from INCLUSIVE.

=item endTime

[OPTIONAL] timestamp in ms to get aggregate trades until INCLUSIVE.

=item limit

[OPTIONAL] Default 500; max 500.

=back

B<RETURNS>
    An ARRAYref of HASHrefs

    [
      {
        "a": 26129,         // Aggregate tradeId
        "p": "0.01633102",  // Price
        "q": "4.70443515",  // Quantity
        "f": 27781,         // First tradeId
        "l": 27781,         // Last tradeId
        "T": 1498793709153, // Timestamp
        "m": true,          // Was the buyer the maker?
        "M": true           // Was the trade the best price match?
      }
    ]

=cut

sub aggregate_trades {
    my ($self, %params) = @_;

    unless ($params{'symbol'}) {
        $self->log->error('Parameter "symbol" required');
        Binance::Exception::Parameter::Required->throw(
            error => 'Parameter "symbol" required',
            parameters => ['symbol']
        );
    }

    my $query = {
        symbol    => $params{'symbol'},
        fromId    => $params{'fromId'},
        startTime => $params{'startTime'},
        endTime   => $params{'endTime'},
        limit     => $params{'limit'},
    };

    return $self->ua->get('/api/v1/aggTrades', { query => $query } );
}

=head2 klines

    $api->klines( symbol => 'ETHBTC', interval => '1M' );

Kline/candlestick bars for a symbol. Klines are uniquely identified by their
open time.

B<PARAMETERS>

=over

=item symbol

[REQUIRED] Symbol, for example C<ETHBTC>.

=item interval

[REQUIRED] ENUM (kline intervals), for example 1m, 1h, 1d or 1M.

=item limit

[OPTIONAL] Default 500; max 500.

=item startTime

[OPTIONAL] timestamp in ms

=item endTime

[OPTIONAL] timestamp in ms

=back

B<RETURNS>
    An array of ARRAYrefs

    [
      [
        1499040000000,      // Open time
        "0.01634790",       // Open
        "0.80000000",       // High
        "0.01575800",       // Low
        "0.01577100",       // Close
        "148976.11427815",  // Volume
        1499644799999,      // Close time
        "2434.19055334",    // Quote asset volume
        308,                // Number of trades
        "1756.87402397",    // Taker buy base asset volume
        "28.46694368",      // Taker buy quote asset volume
        "17928899.62484339" // Can be ignored
      ]
    ]

=cut

sub klines {
    my ($self, %params) = @_;

    unless ($params{'symbol'}) {
        $self->log->error('Parameter "symbol" required');
        Binance::Exception::Parameter::Required->throw(
            error => 'Parameter "symbol" required',
            parameters => ['symbol']
        );
    }

    unless ($params{'interval'}) {
        $self->log->error('Parameter "interval" required');
        Binance::Exception::Parameter::Required->throw(
            error => 'Parameter "interval" required',
            parameters => ['interval']
        );
    }

    my $query = {
        symbol    => $params{'symbol'},
        interval  => $params{'interval'},
        startTime => $params{'startTime'},
        endTime   => $params{'endTime'},
        limit     => $params{'limit'},
    };

    return $self->ua->get('/api/v1/klines', { query => $query } );
}

=head2 ticker

    $api->ticker( symbol => 'ETHBTC', interval => '1M' );

24 hour price change statistics.

B<PARAMETERS>

=over

=item symbol

[OPTIONAL] Symbol, for example C<ETHBTC>.

=back

B<RETURNS>
    A HASHref or an Array of HASHrefs if no symbol given

    {
      "priceChange": "-94.99999800",
      "priceChangePercent": "-95.960",
      "weightedAvgPrice": "0.29628482",
      "prevClosePrice": "0.10002000",
      "lastPrice": "4.00000200",
      "bidPrice": "4.00000000",
      "askPrice": "4.00000200",
      "openPrice": "99.00000000",
      "highPrice": "100.00000000",
      "lowPrice": "0.10000000",
      "volume": "8913.30000000",
      "openTime": 1499783499040,
      "closeTime": 1499869899040,
      "fristId": 28385,   // First tradeId
      "lastId": 28460,    // Last tradeId
      "count": 76         // Trade count
    }

=cut

sub ticker {
    my ($self, %params) = @_;

    my $query = {
        symbol    => $params{'symbol'},
    };

    return $self->ua->get('/api/v1/ticker/24hr', { query => $query } );
}

=head2 ticker_price

    $api->ticker_price();

Latest price for a symbol or symbols.

B<PARAMETERS>

=over

=item symbol

[OPTIONAL] Symbol, for example C<ETHBTC>. If not given, returns prices of all
symbols.

=back

B<RETURNS>
    A HASHref

    {
      "symbol": "LTCBTC",
      "price": "4.00000200"
    }

    OR an ARRAY of HASHrefs

    [
      {
        "symbol": "LTCBTC",
        "price": "4.00000200"
      },
      {
        "symbol": "ETHBTC",
        "price": "0.07946600"
      }
    ]

=cut

sub ticker_price {
    my ($self, %params) = @_;

    my $query = {
        symbol    => $params{'symbol'},
    };

    return $self->ua->get('/api/v3/ticker/price', { query => $query } );
}

=head2 all_book_tickers

    $api->all_book_tickers();

Best price/qty on the order book for all symbols.

B<PARAMETERS>

=over

=item Takes no parameters.

=back

B<RETURNS>
    An array of HASHrefs

    [
      {
        "symbol": "LTCBTC",
        "bidPrice": "4.00000000",
        "bidQty": "431.00000000",
        "askPrice": "4.00000200",
        "askQty": "9.00000000"
      },
      {
        "symbol": "ETHBTC",
        "bidPrice": "0.07946700",
        "bidQty": "9.00000000",
        "askPrice": "100000.00000000",
        "askQty": "1000.00000000"
      }
    ]

=cut

sub all_book_tickers {
    return $_[0]->ua->get('/api/v1/ticker/allBookTickers');
}

=head2 book_ticker

    $api->book_ticker();

Best price/qty on the order book for a symbol or symbols.

B<PARAMETERS>

=over

=item symbol

[OPTIONAL] Symbol, for example C<ETHBTC>.

=back

B<RETURNS>
    A HASHref

    {
      "symbol": "LTCBTC",
      "bidPrice": "4.00000000",
      "bidQty": "431.00000000",
      "askPrice": "4.00000200",
      "askQty": "9.00000000"
    }

=cut

sub book_ticker {
    my ($self, %params) = @_;

    my $query = {
        symbol    => $params{'symbol'},
    };

    return $self->ua->get('/api/v1/bookTicker', { query => $query } );
}

=head2 order

    $api->order(
        symbol => 'ETHBTC',
        side   => 'BUY',
        type   => 'LIMIT',
        timeInForce => 'GTC',
        quantity => 1
        price => 0.1
    );

Send in a new order.

B<PARAMETERS>

=over

=item symbol

[REQUIRED] Symbol, for example C<ETHBTC>.

=item side

[REQUIRED] BUY or SELL.

=item type

[REQUIRED] LIMIT|STOP_LOSS|STOP_LOSS_LIMIT|TAKE_PROFIT|TAKE_PROFIT_LIMIT|LIMIT_MAKER|MARKET.

=item timeInForce

[OPTIONAL] GTC or IOC.

=item quantity

[OPTIONAL] Quantity (of symbols) in order.

=item quoteOrderQty

[OPTIONAL] MARKET orders using quoteOrderQty specifies the amount the user wants
to spend (when buying) or receive (when selling) the quote asset; the correct
quantity will be determined based on the market liquidity and quoteOrderQty.

E.g. Using the symbol BTCUSDT:
BUY side, the order will buy as many BTC as quoteOrderQty USDT can.
SELL side, the order will sell as much BTC needed to receive quoteOrderQty USDT.

=item price

[OPTIONAL] Price (of symbol) in order.

=item newClientOrderId

[OPTIONAL] A unique id for the order. Automatically generated
if not sent.

=item stopPrice

[OPTIONAL] Used with stop orders.

=item icebergQty

[OPTIONAL] Used with iceberg orders.

=item newOrderRespType

[OPTIONAL] Set the response JSON. ACK, RESULT, or FULL; MARKET and LIMIT order
types default to FULL, all other orders default to ACK.

=item test

[OPTIONAL] Test new order creation and signature/recvWindow long. Creates and
validates a new order but does not send it into the matching engine.

=back

B<RETURNS>
    A HASHref

    {
      "symbol":"LTCBTC",
      "orderId": 1,
      "clientOrderId": "myOrder1" // Will be newClientOrderId
      "transactTime": 1499827319559
    }

=cut

sub order {
    my ($self, %params) = @_;

    unless (defined $params{'type'}) {
        $self->log->error('Parameter "type" required');
        Binance::Exception::Parameter::Required->throw(
            error => 'Parameter "type" required',
            parameters => ['type']
        );
    }

    my @required = (
        'symbol', 'side',
    );

    if ($params{'type'} eq 'LIMIT') {
        push @required, ('timeInForce', 'quantity', 'price');
    }
    elsif ($params{'type'} eq 'STOP_LOSS') {
        push @required, ('quantity', 'stopPrice');
    }
    elsif ($params{'type'} eq 'STOP_LOSS_LIMIT') {
        push @required, ('timeInForce', 'quantity', 'price', 'stopPrice');
    }
    elsif ($params{'type'} eq 'TAKE_PROFIT') {
        push @required, ('quantity', 'stopPrice');
    }
    elsif ($params{'type'} eq 'TAKE_PROFIT_LIMIT') {
        push @required, ('timeInForce', 'quantity', 'price', 'stopPrice');
    }
    elsif ($params{'type'} eq 'LIMIT_MAKER') {
        push @required, ('quantity', 'price');
    }
    elsif ($params{'type'} eq 'MARKET') {
        if (!defined $params{'quantity'} && !defined $params{'quoteOrderQty'}) {
            $self->log->error('One of parameters "quantity" or "quoteOrderQty" is required');
            Binance::Exception::Parameter::Required->throw(
                error => 'One of parameters "quantity" or "quoteOrderQty" is required',
                parameters => ["quantity", "quoteOrderQty"]
            );
        }
    } else {
        $self->log->error('Invalid value for parameter "type"');
        Binance::Exception::Parameter::BadValue->throw(
            error => 'Invalid value for parameter "type"',
            parameters => ["type"],
            format => '(LIMIT|STOP_LOSS|STOP_LOSS_LIMIT|TAKE_PROFIT|TAKE_PROFIT_LIMIT|LIMIT_MAKER|MARKET)'
        );
    }

    foreach my $param (@required) {
        unless (defined ($params{$param})) {
            $self->log->error('Parameter "'.$param.'" required');
            Binance::Exception::Parameter::Required->throw(
                error => 'Parameter "'.$param.'" required',
                parameters => [$param]
            );
        }
    }

    my $body = {
        symbol           => $params{'symbol'},
        side             => $params{'side'},
        type             => $params{'type'},
        timeInForce      => $params{'timeInForce'},
        quantity         => $params{'quantity'},
        quoteOrderQty    => $params{'quoteOrderQty'},
        price            => $params{'price'},
        newClientOrderId => $params{'newClientOrderId'},
        stopPrice        => $params{'stopPrice'},
        icebergQty       => $params{'icebergQty'},
        newOrderRespType => $params{'newOrderRespType'},
    };

    # Enable dry mode
    my $url = '/api/v3/order';

    if ($params{'test'}) {
        $self->{logger}->debug('Test flag enabled - using order_test() instead of order()');
        $url .= '/test'
    }

    return $self->ua->post($url, { signed => 1, body => $body } );
}

=head2 order_test

    $api->order_test();

Test new order creation and signature/recvWindow long. Creates and validates
a new order but does not send it into the matching engine.

B<PARAMETERS>

    Same as C<order()>.

B<RETURNS>
    An empty HASHref

    {}

=cut

sub order_test {
    my ($self, %params) = @_;

    $params{'test'} = 1;

    return $self->order(%params);
}

=head2 cancel_order

    $api->cancel_order();

Cancel an active order.

B<PARAMETERS>

=over

=item symbol

[REQUIRED] Symbol, for example C<ETHBTC>.

=item orderId

[OPTIONAL]

=item origClientOrderId

[OPTIONAL]

=item newClientOrderId

[OPTIONAL] Used to uniquely identify this cancel.
Automatically generated by default.

=item recvWindow

[OPTIONAL]

=back

B<RETURNS>
    A HASHref

    {
      "symbol": "LTCBTC",
      "origClientOrderId": "myOrder1",
      "orderId": 1,
      "clientOrderId": "cancelMyOrder1"
    }

=cut

sub cancel_order {
    my ($self, %params) = @_;

    unless ($params{'symbol'}) {
        $self->log->error('Parameter "symbol" required');
        Binance::Exception::Parameter::Required->throw(
            error => 'Parameter "symbol" required',
            parameters => ['symbol']
        );
    }

    my $body = {
        symbol             => $params{'symbol'},
        orderId            => $params{'orderId'},
        origClientOrderId  => $params{'origClientOrderId'},
        newClientOrderId   => $params{'newClientOrderId'},
        recvWindow         => $params{'recvWindow'},
    };

    return $self->ua->delete('/api/v3/order', { signed => 1, body => $body } );
}

=head2 open_orders

    $api->open_orders();

Get all open orders on a symbol. Careful when accessing this with no symbol.

B<PARAMETERS>

=over

=item symbol

OPTIONAL] Symbol, for example C<ETHBTC>.

=item recvWindow

[OPTIONAL]

=back

B<RETURNS>
    An ARRAYref of HASHrefs

    [
      {
        "symbol": "LTCBTC",
        "orderId": 1,
        "clientOrderId": "myOrder1",
        "price": "0.1",
        "origQty": "1.0",
        "executedQty": "0.0",
        "status": "NEW",
        "timeInForce": "GTC",
        "type": "LIMIT",
        "side": "BUY",
        "stopPrice": "0.0",
        "icebergQty": "0.0",
        "time": 1499827319559,
        "isWorking": trueO
      }
    ]

=cut

sub open_orders {
    my ($self, %params) = @_;

    my $query = {
        symbol     => $params{'symbol'},
        recvWindow => $params{'recvWindow'},
    };
    return $self->ua->get(
        '/api/v3/openOrders', { signed => 1, query => $query }
    );
}

=head2 all_orders

    $api->all_orders();

Get all account orders; active, canceled, or filled.

B<PARAMETERS>

=over

=item symbol

[REQUIRED] Symbol, for example C<ETHBTC>.

=item orderId

[OPTIONAL]

=item limit

[OPTIONAL] Default 500; max 500.

=item recvWindow

[OPTIONAL]

=back

B<RETURNS>
    An ARRAYref of HASHrefs

    [
      {
        "symbol": "LTCBTC",
        "orderId": 1,
        "clientOrderId": "myOrder1",
        "price": "0.1",
        "origQty": "1.0",
        "executedQty": "0.0",
        "status": "NEW",
        "timeInForce": "GTC",
        "type": "LIMIT",
        "side": "BUY",
        "stopPrice": "0.0",
        "icebergQty": "0.0",
        "time": 1499827319559,
        "isWorking": true
      }
    ]

=cut

sub all_orders {
    my ($self, %params) = @_;
    unless ($params{'symbol'}) {
        $self->log->error('Parameter "symbol" required');
        Binance::Exception::Parameter::Required->throw(
            error => 'Parameter "symbol" required',
            parameters => ['symbol']
        );
    }
    my $query = {
        symbol     => $params{'symbol'},
        orderId    => $params{'orderId'},
        limit      => $params{'limit'},
        recvWindow => $params{'recvWindow'},
    };
    return $self->ua->get('/api/v3/allOrders',
        { signed => 1, query => $query }
    );
}

=head2 account

    $api->account();

Get current account information.

B<PARAMETERS>

=over

=item recvWindow

[OPTIONAL]

=back

B<RETURNS>
    A HASHref

    {
      "makerCommission": 15,
      "takerCommission": 15,
      "buyerCommission": 0,
      "sellerCommission": 0,
      "canTrade": true,
      "canWithdraw": true,
      "canDeposit": true,
      "updateTime": 123456789,
      "balances": [
        {
          "asset": "BTC",
          "free": "4723846.89208129",
          "locked": "0.00000000"
        },
        {
          "asset": "LTC",
          "free": "4763368.68006011",
          "locked": "0.00000000"
        }
      ]
    }

=cut

sub account {
    my ($self, %params) = @_;

    my $query = {
        recvWindow => $params{'recvWindow'},
    };
    return $self->ua->get('/api/v3/account', { signed => 1, query => $query } );
}

=head2 my_trades

    $api->my_trades();

Get trades for a specific account and symbol.

B<PARAMETERS>

=over

=item symbol

[REQUIRED] Symbol, for example C<ETHBTC>.

=item limit

[OPTIONAL] Default 500; max 500.

=item fromId

[OPTIONAL] TradeId to fetch from. Default gets most recent
trades.

=item recvWindow

[OPTIONAL]

=back

B<RETURNS>
    An ARRAYref of HASHrefs

    [
      {
        "id": 28457,
        "orderId": 100234,
        "price": "4.00000100",
        "qty": "12.00000000",
        "commission": "10.10000000",
        "commissionAsset": "BNB",
        "time": 1499865549590,
        "isBuyer": true,
        "isMaker": false,
        "isBestMatch": true
      }
    ]

=cut

sub my_trades {
    my ($self, %params) = @_;
    unless ($params{'symbol'}) {
        $self->log->error('Parameter "symbol" required');
        Binance::Exception::Parameter::Required->throw(
            error => 'Parameter "symbol" required',
            parameters => ['symbol']
        );
    }
    my $query = {
        symbol     => $params{'symbol'},
        limit      => $params{'limit'},
        fromId    => $params{'fromId'},
        recvWindow => $params{'recvWindow'},
    };
    return $self->ua->get(
        '/api/v3/myTrades', { signed => 1, query => $query }
    );
}

=head2 start_user_data_stream

    $api->start_user_data_stream();

Start a new user data stream. The stream will close after 60 minutes unless
a keepalive is sent.

B<PARAMETERS>

=over

=item Takes no parameters.

=back

B<RETURNS>
    A HASHref

    {
      "listenKey": "pqia91ma19a5s61cv6a81va65sdf19v8a65a1a5s61cv6a81va65sdf19v8a65a1"
    }

=cut

sub start_user_data_stream {
    return $_[0]->ua->post('/api/v1/ticker/userDataStream');
}

=head2 keep_alive_user_data_stream

    $api->keep_alive_user_data_stream();

Keepalive a user data stream to prevent a time out. User data streams will close
after 60 minutes. It's recommended to send a ping about every 30 minutes.

B<PARAMETERS>

=over

=item listenKey

[REQUIRED]

=back

B<RETURNS>
    An empty HASHref

    {}

=cut

sub keep_alive_user_data_stream {
    my ($self, %params) = @_;
    unless ($params{'listenKey'}) {
        $self->log->error('Parameter "listenKey" required');
        Binance::Exception::Parameter::Required->throw(
            error => 'Parameter "listenKey" required',
            parameters => ['listenKey']
        );
    }
    my $query = {
        listenKey  => $params{'listenKey'},
    };
    return $self->ua->put('/api/v1/userDataStream', { query => $query } );
}

=head2 delete_user_data_stream

    $api->delete_user_data_stream();

Close out a user data stream.

B<PARAMETERS>

=over

=item listenKey

[REQUIRED]

=back

B<RETURNS>
    An empty HASHref

    {}

=cut

sub delete_user_data_stream {
    my ($self, %params) = @_;
    unless ($params{'listenKey'}) {
        $self->log->error('Parameter "listenKey" required');
        Binance::Exception::Parameter::Required->throw(
            error => 'Parameter "listenKey" required',
            parameters => ['listenKey']
        );
    }
    my $query = {
        listenKey  => $params{'listenKey'},
    };
    return $self->ua->delete('/api/v1/userDataStream', { query => $query } );
}

=head2 log

    $api->log->warn("This is a warning");

B<PARAMETERS>

=over

=item Takes no parameters.

=back

B<RETURNS>

An instance of L<Binance::API::Logger>.

=cut

sub log { return $_[0]->{logger}; }

=head2 ua

    $api->ua->get('/binance/endpoint');

B<PARAMETERS>

=over

=item Takes no parameters.

=back

B<RETURNS>

An instance of L<Binance::API::Request>.

=cut

sub ua  { return $_[0]->{ua}; }

1;
