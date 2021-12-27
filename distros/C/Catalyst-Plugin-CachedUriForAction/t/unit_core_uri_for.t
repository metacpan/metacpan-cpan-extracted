use strict;
use warnings;

use Test::More;
use URI;

use lib 't/lib';
use TestApp;

my $request = Catalyst::Request->new( {
                _log => Catalyst::Log->new,
                base => URI->new('http://127.0.0.1/foo')
              } );
my $dispatcher = TestApp->dispatcher;
my $context = TestApp->new( {
                request => $request,
              } );

is(
    $context->uri_for_action( '/yada', 'quux', { param1 => 'value1' } )->as_string,
    'http://127.0.0.1/foo/yada/quux?param1=value1',
    'URI for undef action with query params'
);

is ($context->uri_for_action( '/bar', 'wibble?' )->as_string,
   'http://127.0.0.1/foo/bar/wibble%3F', 'Question Mark gets encoded'
);

is( $context->uri_for_action( '/yada', qw/bar wibble?/, 'with space' )->as_string,
    'http://127.0.0.1/foo/yada/bar/wibble%3F/with%20space', 'Space gets encoded'
);

is(
    $context->uri_for_action( '/bar', 'with+plus', { 'also' => 'with+plus' })->as_string,
    'http://127.0.0.1/foo/bar/with+plus?also=with%2Bplus',
    'Plus is not encoded'
);

is(
    $context->uri_for_action( '/bar', 'with space', { 'also with' => 'space here' })->as_string,
    'http://127.0.0.1/foo/bar/with%20space?also+with=space+here',
    'Spaces encoded correctly'
);

is(
    $context->uri_for_action( '/bar', { param1 => 'value1' }, \'fragment' )->as_string,
    'http://127.0.0.1/foo/bar?param1=value1#fragment',
    'URI for path with fragment and query params 1'
);

is(
    TestApp->uri_for_action( '/quux', { param1 => 'value1' } )->as_string,
    '/quux?param1=value1',
    'URI for quux action with query params, called with only class name'
);

is (TestApp->uri_for_action( '/bar', 'wibble?' )->as_string,
   '/bar/wibble%3F', 'Question Mark gets encoded, called with only class name'
);

is(
    TestApp->uri_for_action( '/bar', 'with+plus', { 'also' => 'with+plus' })->as_string,
    '/bar/with+plus?also=with%2Bplus',
    'Plus is not encoded, called with only class name'
);

is(
    TestApp->uri_for_action( '/bar', 'with space', { 'also with' => 'space here' })->as_string,
    '/bar/with%20space?also+with=space+here',
    'Spaces encoded correctly, called with only class name'
);

# test with utf-8
is(
    $context->uri_for_action( '/yada', 'quux', { param1 => "\x{2620}" } )->as_string,
    'http://127.0.0.1/foo/yada/quux?param1=%E2%98%A0',
    'URI for undef action with query params in unicode'
);
is(
    $context->uri_for_action( '/yada','quux', { 'param:1' => "foo" } )->as_string,
    'http://127.0.0.1/foo/yada/quux?param%3A1=foo',
    'URI for undef action with query params in unicode'
);

# test with object
is(
    $context->uri_for_action( '/yada', 'quux', { param1 => $request->base } )->as_string,
    'http://127.0.0.1/foo/yada/quux?param1=http%3A%2F%2F127.0.0.1%2Ffoo',
    'URI for undef action with query param as object'
  );

{
    $request->base( URI->new('http://127.0.0.1/') );

    $context->namespace('');

    is( $context->uri_for_action( '/bar', 'baz' )->as_string,
        'http://127.0.0.1/bar/baz', 'URI with no base or match' );

}

# test with undef -- no warnings should be thrown
{
    my $warnings = 0;
    local $SIG{__WARN__} = sub { $warnings++ };

    $context->uri_for_action( '/bar', 'baz', { foo => undef } )->as_string,
    is( $warnings, 0, "no warnings emitted" );
}

# make sure caller's query parameter hash isn't messed up
{
    my $query_params_base = {test => "one two",
                             bar  => ["foo baz", "bar"]};
    my $query_params_test = {test => "one two",
                             bar  => ["foo baz", "bar"]};
    $context->uri_for_action('/bar', 'baz', $query_params_test);
    is_deeply($query_params_base, $query_params_test,
              "uri_for() doesn't mess up query parameter hash in the caller");
}


{
    my $path_action = '/action/path/six';

    # 5.80018 is only encoding the first of the / in the arg.
    is(
        $context->uri_for_action( $path_action, 'foo/bar/baz' )->as_string,
        'http://127.0.0.1/action/path/six/foo%2Fbar%2Fbaz',
        'Escape all forward slashes in args as %2F'
    );
}

{
    my $index_not_private = '/action/chained/argsorder/index';

    is(
      $context->uri_for_action( $index_not_private )->as_string,
      'http://127.0.0.1/argsorder',
      'Return non-DispatchType::Index path for index action with args'
    );
}

{
    package MyStringThing;

    use overload '""' => sub { $_[0]->{string} }, fallback => 1;
}

is(
    $context->uri_for_action( bless( { string => '/test' }, 'MyStringThing' ) ),
    'http://127.0.0.1/test',
    'overloaded object handled correctly'
);

is(
    $context->uri_for_action( bless( { string => '/test' }, 'MyStringThing' ), \'fragment' ),
    'http://127.0.0.1/test#fragment',
    'overloaded object handled correctly'
);

done_testing;
