use strict;
use warnings;
use Test::More;
use Crypto::API;

{package mocker;
    use Moo::Role;
    sub get {}
    sub json_response {
        return {
            data => {
                symbol => 'XRP-USDT',
                last   => 1234,
                time   => time,
            }
        };
    }
}

{package foo;
    use Moo;
    extends 'Crypto::API';
    with 'mocker';

    sub _build_base_url {
        URI->new('https://api.kucoin.com');
    }

    sub set_prices {{
        request => {
            method => 'get',
            path   => '/api/v1/market/stats',
            data   => {
                pair => {
                    field_name => 'symbol',
                    checker => [
                        {
                            ok  => sub { /XRP/ },
                            err => 'only support XRP',
                        },
                    ],
                },
            },
        },
        response => {},
    }}
}

my $foo = foo->new;

eval { $foo->prices(pair => 'BTC') };

like $@, qr/pair only support XRP/;

done_testing;
