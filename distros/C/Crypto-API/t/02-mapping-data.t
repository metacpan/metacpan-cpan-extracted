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

	sub request_attr_pair {
		my ($self, $pair) = @_; 
		return join '-', map {uc} @$pair{qw( coin base )};
	}

	sub response_attr_pair {
		my ($self, $pair) = @_; 
		my %pair = ();
	    @pair{qw( coin base )} = split /-/, $pair;	
        return \%pair;
	}

    sub set_prices {{
        request => {
            method => 'get',
            path   => '/api/v1/market/stats',
            data   => {
                pair => 'symbol',
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

my %pair = (coin => 'XRP', base => 'USDT');

my $data = $foo->prices( pair => \%pair );

ok exists $data->{pair};
ok exists $data->{last_price};
ok exists $data->{_others}{symbol};
ok exists $data->{_others}{time};

is_deeply $data->{pair}, \%pair;
like $data->{last_price}, qr/^[\d\.]+$/;

done_testing;
