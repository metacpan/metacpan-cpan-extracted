use strict;
use warnings;
use Test::More;
use Crypto::API;

{

    package mocker;
    use Moo::Role;
    sub get { }

    sub json_response {
        return {
            code => 200,
            data => {
                page  => 1,
                size  => 50,
                total => 2,
                items => [
                    {
                        symbol => 'XRP-USDT',
                        price  => 12,
                        time   => time,
                    },
                    {
                        symbol => 'XRP-USDT',
                        price  => 13,
                        time   => time,
                    },
                ],
            },
        };
    }
}

{

    package foo;
    use Moo;
    extends 'Crypto::API';
    with 'mocker';

    sub _build_base_url {
        URI->new('https://api.kucoin.com');
    }

    sub set_orders {
        {
            request => {
                method => 'get',
                path   => '/api/v1/market/stats',
            },
            response => [
                {
                    key => 'data.items',
                    row => {
                        pair  => 'symbol',
                        price => 'price',
                        time  => 'time',
                    },
                    sort_by => [ { ndesc => 'price' } ]
                },
                {
                    key => 'data',
                    row => {
                        page  => 'page',
                        size  => 'size',
                        total => 'total',
                    },
                }
            ]
        }
    }
}

my $foo = foo->new;

my ( $orders, $pagination ) = $foo->orders;

is_deeply $orders,
  [
    {
        pair  => 'XRP-USDT',
        price => 13,
        time  => time,
    },
    {
        pair  => 'XRP-USDT',
        price => 12,
        time  => time,
    },
  ];

is_deeply $pagination,
  {
    page  => 1,
    size  => 50,
    total => 2,
  };

my $same_orders_skip_pagination = $foo->orders;

is_deeply $same_orders_skip_pagination, $orders;

done_testing;
