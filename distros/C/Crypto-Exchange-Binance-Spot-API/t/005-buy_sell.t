use strict;
use warnings;
use Test::More;
use Crypto::Exchange::Binance::Spot::API;

{

    package TestResponse;
    use Moo;
    extends 'Crypto::Exchange::Binance::Spot::API';
    sub send { }

    sub json_response {
        {
            clientOrderId       => "6gCrw2kRUAF9CvJDGP16IP",
            cummulativeQuoteQty => "10.00000000",
            executedQty         => "10.00000000",
            time                => time,
            fills               => [
                {
                    commission      => "4.00000000",
                    commissionAsset => "USDT",
                    price           => "4000.00000000",
                    qty             => "1.00000000"
                },
                {
                    commission      => "19.99500000",
                    commissionAsset => "USDT",
                    price           => "3999.00000000",
                    qty             => "5.00000000"
                },
                {
                    commission      => "7.99600000",
                    commissionAsset => "USDT",
                    price           => "3998.00000000",
                    qty             => "2.00000000"
                },
                {
                    commission      => "3.99700000",
                    commissionAsset => "USDT",
                    price           => "3997.00000000",
                    qty             => "1.00000000"
                },
                {
                    commission      => "3.99500000",
                    commissionAsset => "USDT",
                    price           => "3995.00000000",
                    qty             => "1.00000000"
                }
            ],
            orderId     => 28,
            orderListId => -1,
            origQty     => "10.00000000",
            price       => "0.00000000",
            side        => "SELL",
            status      => "FILLED",
            symbol      => "BTCUSDT",
            timeInForce => "GTC",

            transactTime => '1507725176595',
            type         => "MARKET"
        }
    }
}

my $binance = TestResponse->new;

my %pair = ( coin => 'XRP', base => 'GBP' );

eval { $binance->buy };

like $@, qr/Missing Argument: (?:price|pair|amount)/i,

  eval { $binance->buy( pair => \%pair ) };

like $@, qr/Missing Argument: (?:price|pair|amount)/i,

  eval { $binance->buy( pair => \%pair, amount => 100 ) };

like $@, qr/Missing Argument: (?:price|pair|amount)/i;

my $data = $binance->buy( pair => \%pair, amount => 100, price => 1.1 );

is_deeply do {delete @$data{qw(timestamp)}; $data},
  {
    _others => {
        cummulativeQuoteQty => "10.00000000",
        fills               => [
            {
                commission      => "4.00000000",
                commissionAsset => "USDT",
                price           => "4000.00000000",
                qty             => "1.00000000"
            },
            {
                commission      => "19.99500000",
                commissionAsset => "USDT",
                price           => "3999.00000000",
                qty             => "5.00000000"
            },
            {
                commission      => "7.99600000",
                commissionAsset => "USDT",
                price           => "3998.00000000",
                qty             => "2.00000000"
            },
            {
                commission      => "3.99700000",
                commissionAsset => "USDT",
                price           => "3997.00000000",
                qty             => "1.00000000"
            },
            {
                commission      => "3.99500000",
                commissionAsset => "USDT",
                price           => "3995.00000000",
                qty             => "1.00000000"
            }
        ],
        origQuoteOrderQty => undef,
        isWorking         => undef,
        icebergQty        => undef,
        updateTime        => undef, stopPrice => undef,
        timeInForce       => "GTC",
        orderListId       => -1,
    },
    price       => "0.00000000",
    status      => "FILLED",
    order_type  => "MARKET",
    buy_or_sell => "SELL",
    external_id => "6gCrw2kRUAF9CvJDGP16IP",
    order_id    => 28,
    order_qty   => "10.00000000",
    pair        => {
        base => "USDT",
        coin => "BTC"
    },
  };

done_testing;
