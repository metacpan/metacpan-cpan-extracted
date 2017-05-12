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
                params_filter => '^(?i)mytest$',
            },
        };
    }
    use Dancer::Plugin::Params::Normalization;

    get '/foo/:name' => sub {
		return params->{params->{name}};
    };
}

# param filter regexp doesn't match, thus the param is no lowercased
my $response = dancer_response GET => '/foo/test', { params => {TEST => 5 } };
ok(! length $response->{content});

# param filter regexp matches, thus the param is no lowercased
$response = dancer_response GET => '/foo/mytest', { params => {MYTEST => 5 } };
is($response->{content}, 5);

