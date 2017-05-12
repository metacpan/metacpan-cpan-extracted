use strict;
use warnings;

use Test::More;
use Dancer::Test;

plan tests => 2;

{
    package Webservice;
    use Dancer;

    BEGIN {
        set plugins => {
            'Params::Normalization' => {
                method => 'lowercase',
                general_rule => 'ondemand',
            },
        };
    }
    use Dancer::Plugin::Params::Normalization;

    # no normalization in this route
    get '/foo' => sub {
		return params->{test};
    };

    # this route normalizes its parameters names
    get '/bar' => sub {
        normalize;
		return params->{test};
    };


}

# this route doesn't do parameters normalization
my $response = dancer_response GET => '/foo', { params => {TEST => 5 } };
ok(! length $response->{content});

# this route does parameters normalization
$response = dancer_response GET => '/bar', { params => {TEST => 5 } };
is($response->{content}, 5);

