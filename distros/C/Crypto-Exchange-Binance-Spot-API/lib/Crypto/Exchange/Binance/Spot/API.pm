package Crypto::Exchange::Binance::Spot::API;
$Crypto::Exchange::Binance::Spot::API::VERSION = '0.02';
=head1 NAME

Crypto::Exchange::Binance::Spot::API - Binance Spot API

=head1 USAGE

 my $binance = Crypto::Exchange::Binance::Spot::API->new;

Get Prices

 $hash = $binance->prices(pair => { coin => 'XRP', base => 'GBP' });

 Got: $hash = { last_price => 1234, pair => {coin => 'XRP', base => 'GBP'} }

Get Wallet Balances

 $hash = $binance->balances();

 Got: $hash = {
    XRP => { available => 123, in_order => 0, staking => 0 },
    GBP => { available => 321, in_order => 0, staking => 0 },
 }

Get the opening orders

 $list = $binance->list_open_orders(pair => { coin => 'XRP', base => 'GBP' });

 Got: $list = [
    {
        pair => { coin => 'XRP', base => 'GBP' },
        order_id => 123,
        external_id => 'YOUR OWN DEFINED ID',
        buy_or_sell => 'buy|sell',
        order_qty   => 55,
        filled_qty  => 54,
        timestamp   => 131321321321,
        filled_qty  => 131231321321,
    },
    ...
 ];

=head2 Open Source

 git@github.com:mvu8912/perl5-crypto-exchange-binance-spot-api.git

=cut

use Moo;
use DateTime;

extends 'Crypto::Exchange::API';

sub _build_key {}

sub _build_secret {}

sub _build_base_url {
    return URI->new('https://api.binance.com');
}

sub _build_pre_defined_headers {
    my ($self) = @_;
    if ($self->key) {
        return {'X-MBX-APIKEY' => $self->key};
    }
    else {
        return {};
    }
}

sub _build_pre_defined_data {
    return {
        timestamp => sub { time * 1000 },
        signature => sub {
            my ($self, %o) = @_;
            if ($self->secret) {
                my $params = $self->kvp2str(%o, skip_key => { signature => 1 });
                $self->do_hmac_sha256_hex($params, $self->secret);
            }
        },
    };
}

sub _build_base_currencies {
    return {
        BTC  => 1,
        ETH  => 1,
        TRX  => 1,
        USDT => 1,
        TUSD => 1,
        USDC => 1,
        BUSD => 1,
        AUD  => 1,
        BRL  => 1,
        EUR  => 1,
        RUB  => 1,
        GBP  => 1,
        TRY  => 1,
        PAX  => 1,
        BIRD => 1,
        DAI  => 1,
        IDRT => 1,
        NGN  => 1,
        UAH  => 1,
        VAI  => 1,
        BVND => 1,
    };
}

sub request_attr_pair {
    my ($self, $pair) = @_;
    return join '', map {uc} @$pair{qw( coin base )};
}

sub response_attr_pair {
    my ($self, $pair) = @_;
    my $bases = $self->base_currencies;

    foreach my $base(keys %$bases) {
        if ($pair =~ m/^$base(.+)/ || $pair =~ m/(.+)$base$/) {
            return { base => $base, coin => $1 },
        }
    }

    die "Pair [$pair] couldnn't find base currency";
}

sub response_attr_timestamp {
    my ($self, $epoch) = @_;
    return DateTime->from_epoch(epoch => $epoch / 1000) . '';
}

sub response_attr_filled_time {
    my ($self, $epoch) = @_;
    return DateTime->from_epoch(epoch => $epoch / 1000) . '';
}

sub set_prices {{
    request => {
        method => 'get',
        path   => '/api/v3/ticker/price',
        data   => {
            pair => 'symbol',
        },
        events => {
            keys => sub { 'pair' }
        },
    },
    response => {
        row => {
            pair       => 'symbol',
            last_price => 'price',
        },
    },
}}

sub set_balances {{
    request => {
        method => 'get',
        path   => '/api/v3/account',
        events => {
            keys => sub { qw( timestamp signature ) },
        },
    },
    response => {
        key  => 'balances',
        row  => {
            coin      => 'asset',
            available => 'free',
            in_order  => 'locked',
        },
        row_filter => sub {
            my ($self, $row) = @_;
            if ($row->{available} == 0 && $row->{in_order} == 0) {
                return 'next';
            }
        },
        array2hash => 'coin',
        post_row => sub {
            my ($self, $row, $rows) = @_;
            my $coin = $row->{coin};
            return if $coin =~ m/^LD/;
            my $earn = delete $rows->{"LD$coin"} || {available => 0};
            $rows->{$coin}{staking} = $earn->{available};
        },
    },
}}

sub set_list_open_orders {{
    request => {
        method => 'get',
        path   => '/api/v3/openOrders',
        events => {
            keys => sub { qw( pair timestamp signature ) }
        },
        data => {
            pair => 'symbol',
        },
    },
    response => {
        row => {
            pair        => 'symbol',
            order_id    => 'orderId',
            external_id => 'clientOrderId',
            buy_or_sell => 'side',
            order_qty   => 'origQty',
            filled_qty  => 'executedQty',
            timestamp   => 'time',
            filled_time => 'updateTime',
            _others     => [qw(
                status
                type
                price
                orderListId
                cummulativeQuoteQty
                timeInForce
                stopPrice
                icebergQty
                updateTime
                isWorking
                origQuoteOrderQty
            )],
        },
        row_filter => sub {
            my ($self, $row) = @_;
            $row->{isWorking} = $row->{isWorking} ? 1 : 0;
        },
        sort => sub {
            my ($self, $a, $b) = @_;
            return $b->{price} <=> $a->{price};
        },
    },
}}

sub set_list_all_orders {{
    request => {
        method => 'get',
        path   => '/api/v3/allOrders',
        events => {
            keys => sub { qw( pair order_id start_time end_time page_size timestamp signature ) }
        },
        data => {
            pair => 'symbol',
            order_id => 'orderId',
            start_time => 'startTime',
            end_time   => 'endTime',
            page_size  => 'limit',
        },
    },
    response => {
        row => {
            pair        => 'symbol',
            order_id    => 'orderId',
            external_id => 'clientOrderId',
            buy_or_sell => 'side',
            order_qty   => 'origQty',
            filled_qty  => 'executedQty',
            timestamp   => 'time',
            filled_time => 'updateTime',
            _others     => [qw(
                status
                type
                price
                orderListId
                cummulativeQuoteQty
                timeInForce
                stopPrice
                icebergQty
                isWorking
                origQuoteOrderQty
            )],
        },
        row_filter => sub {
            my ($self, $row) = @_;
            $row->{isWorking} = $row->{isWorking} ? 1 : 0;
        },
        sort => sub {
            my ($self, $a, $b) = @_;
            return ($b->{filled_time} || 0) cmp ($a->{filled_time} || 0);
        },
    },
}}

sub DESTROY {}

no Moo;

1;
