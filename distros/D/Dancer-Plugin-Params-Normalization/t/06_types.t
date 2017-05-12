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
                params_types => [ qw (route) ],
            },
        };
    }
    use Dancer::Plugin::Params::Normalization;

    # the real test is done here : the route param is called 'NAME', but accessed
    # as 'name'
    get '/foo/:NAME' => sub {
		return params->{params->{name}};
    };
}

# only route params are lowercase'd
my $response = dancer_response GET => '/foo/test', { params => {TEST => 5 } };
ok(! length $response->{content});


# route param (:NAME) is lowercased to 'name', and returns 'plop'
$response = dancer_response GET => '/foo/plop', { params => { plop => 5 } };
is($response->{content}, 5);

