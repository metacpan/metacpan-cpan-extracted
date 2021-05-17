use strict;
use warnings;
use Test::More import => ['!pass'];
use Plack::Test;
use HTTP::Request::Common;
use Ref::Util qw<is_coderef>;

{
    package App1;
    use Dancer2;
    use Dancer2::Plugin::Syntax::ParamKeywords;

    get '/a/:foo/:bar' => sub { return "foo = " . route_param('foo') . ", bar = " . route_param( 'bar' ) };
    
    get '/b' => sub { return 'bar = ' . query_param( 'bar' ) };
    
    get '/c' => sub { return join( ', ', query_params( 'foo' ) ) };

    get '/d' => sub { 
        my $params = query_params;
        
        ::isa_ok(
            $params,
            'Hash::MultiValue',
            '...query_params',
        );

        return join( ', ', sort $params->values ) ;
    };

    post '/e' => sub {
        my $params = body_parameters;
        ::isa_ok(
            $params,
            'Hash::MultiValue',
            '..body_params',
        );

        ::is_deeply(
            [ sort $params->values ],
            ['bar', 'baz', 'blah', 'quux'],
            '...got all values for body_params',
        );

        ::is( body_param( 'foo' ), 'bar', '...got a single value' );

        ::is_deeply(
            [ body_params( 'bar' ) ],
            ['baz', 'quux'],
            '...got all values for a sing body param',
        );
    };

    get '/f/:foo/:bar' => sub { 
        my $params = route_params;
        
        ::isa_ok(
            $params,
            'Hash::MultiValue',
            '...route_params',
        );

        ::is_deeply(
            [ sort $params->values ],
            [ 'bah', 'baz' ],
            '...got all values for route_params',
        );
    };

    true;
}

my $app = App1->to_app;
ok( is_coderef( $app ), 'Got a test app' );

test_psgi $app, sub {
    my $cb = shift;

    is(
        $cb->( GET '/a/baz/bah' )->content,
        'foo = baz, bar = bah',
        '...and tested the route_param keyword',
    );

    $cb->( GET '/f/baz/bah' );

    is(
        $cb->( GET '/b?foo=baz&foo=bah&bar=blah' )->content,
        'bar = blah',
        '...and the query_param keyword',
    );

    is(
        $cb->( GET '/c?foo=baz&foo=bah&bar=blah' )->content,
        'baz, bah',
        '...also, all query_params for foo',
    );

    is(
        $cb->( GET '/d?foo=baz&foo=bah&bar=blah' )->content,
        'bah, baz, blah',
        '...and were captured correctly',
    );

    $cb->(
        POST '/e',
        Content => [ foo => 'bar', bar => 'baz', bar => 'quux', baz => 'blah' ],
    );
};

done_testing;
# COPYRIGHT
