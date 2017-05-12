use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../t";

use Test::More;
use Dancer::Test;

plan tests => 2;

{
    package Webservice;
    use Dancer;

    BEGIN {
        set plugins => {
            'Params::Normalization' => {
                method => 'MyNormalization2',
            },
        };
    }
    use Dancer::Plugin::Params::Normalization;

    # no normalization in this route
    get '/foo' => sub {
		return params->{ing};
    };

    # this route normalizes its parameters names
    get '/bar' => sub {
		return params->{AME};
    };


}

# 'testing' should be shortened to 'ing'
my $response = dancer_response GET => '/foo', { params => {testing => 5 } };
is($response->{content}, 5);

# 'ABCLONGNAME' should be shortened to 'AME'
$response = dancer_response GET => '/bar', { params => { ABCLONGNAME => 6 } };
is($response->{content}, 6);
