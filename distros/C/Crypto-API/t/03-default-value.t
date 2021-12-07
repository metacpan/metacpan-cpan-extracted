use strict;
use warnings;
use Test::More;

{package foo;
    use Moo;
    extends 'Crypto::API';

    sub _build_base_url {
        URI->new('https://api.kucoin.com');
    }

	sub request_attr_pair {
		my ($self, $pair) = @_; 
		return join '-', map {uc} @$pair{qw( coin base )};
	}

    sub set_price_pair_is_required {{
        request => {
            method => 'get',
            path   => '/api/v1/market/stats',
            data   => {
                pair => {
                    field_name => 'symbol',
                    required   => 1,
                },
            },
            events => {
                test_request_object => 1,
            },
        },
        response => {
            key => 'data',
            row => {
                pair       => 'symbol',
                last_price => 'last',
                _others    => ['symbol', 'time'],
            },
        },
    }}

    sub set_price_with_default_pair {{
        request => {
            method => 'get',
            path   => '/api/v1/market/stats',
            data   => {
                pair => {
                    field_name => 'symbol',
                    default    => {coin => 'XRP', base => 'USDT'},
                },
            },
            events => {
                test_request_object => 1,
            },
        },
        response => {
            key => 'data',
            row => {
                pair       => 'symbol',
                last_price => 'last',
                _others    => ['symbol', 'time'],
            },
        },
    }}
}

my $foo = foo->new;

eval { $foo->price_pair_is_required };

like $@, qr/Missing argument: pair/;

my $expected = qr{/api/v1/market/stats\?symbol=XRP-USDT};

like $foo->price_pair_is_required(pair => {coin => 'XRP', base => 'USDT'})->as_string, $expected;

like $foo->price_with_default_pair->as_string, $expected;

done_testing;
