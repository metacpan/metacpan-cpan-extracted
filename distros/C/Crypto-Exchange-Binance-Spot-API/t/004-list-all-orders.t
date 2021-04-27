## Please see file perltidy.ERR
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
                clientOrderId       => "x-NS8RHAMK_gl_22505570_1",
                cummulativeQuoteQty => "16.25916000",
                executedQty         => "13.80000000",
                icebergQty          => "0.00000000",
                isWorking           => 1,
                orderId             => 35455741,
                orderListId         => -1,
                origQty             => "13.80000000",
                origQuoteOrderQty   => "0.00000000",
                price               => "1.17820000",
                side                => "SELL",
                status              => "FILLED",
                stopPrice           => "0.00000000",
                symbol              => "XRPGBP",
                time                => '1618566302337',
                timeInForce         => "GTC",
                type                => "LIMIT",
                updateTime          => '1618566312494'
            },
            {
                clientOrderId       => "x-NS8RHAMK_gl_22505569_1",
                cummulativeQuoteQty => "0.00000000",
                executedQty         => "0.00000000",
                icebergQty          => "0.00000000",
                isWorking           => 1,
                orderId             => 35455939,
                orderListId         => -1,
                origQty             => "13.80000000",
                origQuoteOrderQty   => "0.00000000",
                price               => "1.17293000",
                side                => "BUY",
                status              => "NEW",
                stopPrice           => "0.00000000",
                symbol              => "XRPGBP",
                time                => '1618566314176',
                timeInForce         => "GTC",
                type                => "LIMIT",
                updateTime          => '1618566314176'
            }
        ]
    }
}

my $binance = Binance->new;

my %pair = ( coin => 'XRP', base => 'GBP' );

my $data = $binance->list_all_orders( pair => \%pair );

is_deeply [map { delete @$_{qw(timestamp filled_time)}; $_ } @$data],
  [
    {
        'status'            => 'FILLED',
        'filled_qty'        => '13.80000000',
        'buy_or_sell'       => 'SELL',
        'external_id'       => 'x-NS8RHAMK_gl_22505570_1',
        'pair'              => {
            'base' => 'GBP',
            'coin' => 'XRP'
        },
        'order_qty'   => '13.80000000',
        'order_id'    => 35455741,
        'price'       => '1.17820000',
        'order_type'  => 'LIMIT',
        _others       => {
            'orderListId'         => -1,
            'cummulativeQuoteQty' => '16.25916000',
            'timeInForce'         => 'GTC',
            'stopPrice'           => '0.00000000',
            'icebergQty'          => '0.00000000',
            'isWorking'           => 1,
            'origQuoteOrderQty'   => '0.00000000',
        },
    },
    {
        'pair' => {
            'base' => 'GBP',
            'coin' => 'XRP'
        },
        'price'       => '1.17293000',
        'order_id'    => 35455939,
        'order_qty'   => '13.80000000',
        'order_type'  => 'LIMIT',
        'status'      => 'NEW',
        'filled_qty'  => '0.00000000',
        'buy_or_sell' => 'BUY',
        'external_id' => 'x-NS8RHAMK_gl_22505569_1',
        _others       => {
            'orderListId'         => -1,
            'cummulativeQuoteQty' => '0.00000000',
            'timeInForce'         => 'GTC',
            'stopPrice'           => '0.00000000',
            'icebergQty'          => '0.00000000',
            'isWorking'           => 1,
            'origQuoteOrderQty'   => '0.00000000',
        },
    },
  ];

done_testing;
