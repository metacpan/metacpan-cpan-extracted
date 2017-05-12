use strict;
use warnings;

use Test::More;
use Dancer::Test;

plan tests => 1;

{
    package Webservice;
    use Dancer;

    BEGIN {
        set plugins => {
            'Params::Normalization' => {
                method => 'ucfirst',
            },
        };
    }
    use Dancer::Plugin::Params::Normalization;

    get '/foo' => sub {
		return params->{TeSt};
    };
}

my $response = dancer_response GET => '/foo', { params => {teSt => 5 } };
is($response->{content}, 5);
