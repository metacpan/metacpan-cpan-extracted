use strict;
use warnings;
use Test::More;
use Crypto::Exchange::Binance::Spot::API;

package Binance {
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

is_deeply $data,
  [
    {
        'pair' => {
            'base' => 'GBP',
            'coin' => 'XRP'
        },
        'price'               => '1.17293000',
        'order_id'            => 35455939,
        'order_qty'           => '13.80000000',
        'type'                => 'LIMIT',
        'timestamp'           => '2021-04-16T09:45:14',
        'timeInForce'         => 'GTC',
        'stopPrice'           => '0.00000000',
        'orderListId'         => -1,
        'filled_time'         => '2021-04-16T09:45:14',
        'status'              => 'NEW',
        'origQuoteOrderQty'   => '0.00000000',
        'filled_qty'          => '0.00000000',
        'cummulativeQuoteQty' => '0.00000000',
        'isWorking'           => 1,
        'buy_or_sell'         => 'BUY',
        'icebergQty'          => '0.00000000',
        'external_id'         => 'x-NS8RHAMK_gl_22505569_1'
    },
    {
        'status'              => 'FILLED',
        'filled_qty'          => '13.80000000',
        'origQuoteOrderQty'   => '0.00000000',
        'cummulativeQuoteQty' => '16.25916000',
        'buy_or_sell'         => 'SELL',
        'isWorking'           => 1,
        'icebergQty'          => '0.00000000',
        'external_id'         => 'x-NS8RHAMK_gl_22505570_1',
        'pair'                => {
            'base' => 'GBP',
            'coin' => 'XRP'
        },
        'order_qty'   => '13.80000000',
        'order_id'    => 35455741,
        'price'       => '1.17820000',
        'type'        => 'LIMIT',
        'timeInForce' => 'GTC',
        'timestamp'   => '2021-04-16T09:45:02',
        'stopPrice'   => '0.00000000',
        'filled_time' => '2021-04-16T09:45:12',
        'orderListId' => -1
    }
  ];

done_testing;
