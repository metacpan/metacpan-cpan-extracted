use strict;
use warnings;
use Test::More;
use Crypto::Exchange::Binance::Spot::API;

{

    package Binance;
    use Moo;
    extends 'Crypto::Exchange::Binance::Spot::API';
    sub send { }

    sub json_response {
        [
            {
                'clientOrderId'       => 'x-NS8RHAMK_gl_22505588_32',
                'cummulativeQuoteQty' => 0.00000000,
                'executedQty'         => 0.00000000,
                'icebergQty'          => 0.00000000,
                'isWorking'           => 1,
                'orderId'             => 35188945,
                'orderListId'         => '-1',
                'origQty'             => 13.80000000,
                'origQuoteOrderQty'   => 0.00000000,
                'price'               => 1.27316000,
                'side'                => 'BUY',
                'status'              => 'NEW',
                'stopPrice'           => 0.00000000,
                'symbol'              => 'XRPGBP',
                'time'                => 1618538883755,
                'timeInForce'         => 'GTC',
                'type'                => 'LIMIT',
                'updateTime'          => 1618538883755
            },
            {
                'clientOrderId'       => 'x-NS8RHAMK_gl_22505590_29',
                'cummulativeQuoteQty' => 0.00000000,
                'executedQty'         => 0.00000000,
                'icebergQty'          => 0.00000000,
                'isWorking'           => 1,
                'orderId'             => 35192621,
                'orderListId'         => '-1',
                'origQty'             => 13.80000000,
                'origQuoteOrderQty'   => 0.00000000,
                'price'               => 1.28371000,
                'side'                => 'SELL',
                'status'              => 'NEW',
                'stopPrice'           => 0.00000000,
                'symbol'              => 'XRPGBP',
                'time'                => 1618539295363,
                'timeInForce'         => 'GTC',
                'type'                => 'LIMIT',
                'updateTime'          => 1618539295363
            },
        ]
    }
}

my $binance = Binance->new;

my %pair = ( coin => 'XRP', base => 'GBP' );

my $data = $binance->list_open_orders( pair => \%pair );

is_deeply [map { delete @$_{qw(timestamp filled_time)}; $_ } @$data],
  [
    {
        'order_id'    => 35192621,
        'external_id' => 'x-NS8RHAMK_gl_22505590_29',
        'order_type'  => 'LIMIT',
        'buy_or_sell' => 'SELL',
        'status'      => 'NEW',
        'pair'        => {
            'base' => 'GBP',
            'coin' => 'XRP'
        },
        'order_qty'  => '13.8',
        'filled_qty' => '0',
        'price'      => '1.28371',
        _others      => {
            'orderListId'         => '-1',
            'cummulativeQuoteQty' => '0',
            'timeInForce'         => 'GTC',
            'stopPrice'           => '0',
            'icebergQty'          => '0',
            'origQuoteOrderQty'   => '0',
            'isWorking'           => 1,
            'updateTime'          => '1618539295363',
        },
    },
    {
        'order_type'  => 'LIMIT',
        'external_id' => 'x-NS8RHAMK_gl_22505588_32',
        'order_id'    => 35188945,
        'price'       => '1.27316',
        'filled_qty'  => '0',
        'pair'        => {
            'base' => 'GBP',
            'coin' => 'XRP'
        },
        'order_qty'   => '13.8',
        'status'      => 'NEW',
        'buy_or_sell' => 'BUY',
        _others       => {
            'cummulativeQuoteQty' => '0',
            'orderListId'         => '-1',
            'timeInForce'         => 'GTC',
            'stopPrice'           => '0',
            'icebergQty'          => '0',
            'origQuoteOrderQty'   => '0',
            'isWorking'           => 1,
            'updateTime'          => '1618538883755',
        },
    },
  ];

done_testing;
