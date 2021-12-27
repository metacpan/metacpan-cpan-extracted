use strict;
use warnings;

use Test::More;

use lib 't/lib';
use TestApp;

#
#   Private Action
#
my $private_action = '/class_forward_test_method';

is(eval{ TestApp->uri_for_action($private_action) }, undef,
   "Private action returns undef for URI");

#
#   Path Action
#
my $path_action = '/action/testrelative/relative';

is(TestApp->uri_for_action($path_action), "/action/relative/relative",
   "Public path action returns correct URI");

is(eval{ TestApp->uri_for_action($path_action, [ 'foo' ]) }, undef,
   "no URI returned for Path action when snippets are given");

#
#   Index Action
#
my $index_action = '/action/index/index';

is(eval{ TestApp->uri_for_action($index_action, [ 'foo' ]) }, undef,
   "no URI returned for index action when snippets are given");

is(TestApp->uri_for_action($index_action),
   "/action/index",
   "index action returns correct path");

#
#   Chained Action
#
my $chained_action = '/action/chained/endpoint';

is(eval{ TestApp->uri_for_action($chained_action) }, undef,
   "Chained action without captures returns undef");

is(eval{ TestApp->uri_for_action($chained_action, [ 1, 2 ], 1) }, undef,
   "Chained action with too many captures returns undef");

is(TestApp->uri_for_action($chained_action, [ 1 ], 1),
   "/chained/foo/1/end/1",
   "Chained action with correct captures returns correct path");

#
#   Tests with Context
#
my $request = Catalyst::Request->new( {
                _log => Catalyst::Log->new,
                base => URI->new('http://127.0.0.1/foo')
              } );

my $context = TestApp->new( {
                request => $request,
                namespace => 'yada',
              } );

is( $context->uri_for_action( '/action/chained/endpoint', [ 1 ], 1 ),
    'http://127.0.0.1/foo/chained/foo/1/end/1',
    "uri_for a controller and action as string");

is(TestApp->uri_for_action($context->controller('Action::Chained')->action_for('endpoint'), [ 1 ], 1),
    '/chained/foo/1/end/1',
    "uri_for a controller and action, called with only class name");

is(TestApp->uri_for_action('/action/chained/endpoint', [ 1 ], 1 ),
    '/chained/foo/1/end/1',
    "uri_for a controller and action as string, called with only class name");

is(TestApp->uri_for_action( $chained_action, [ 1 ], 1 ),
    '/chained/foo/1/end/1',
    "uri_for action via dispatcher, called with only class name");

#
#   More Chained with Context Tests
#
{
    is( $context->uri_for_action( '/action/chained/endpoint2', [1,2], (3,4), { x => 5 } ),
        'http://127.0.0.1/foo/chained/foo2/1/2/end2/3/4?x=5',
        'uri_for_action correct for chained with multiple captures and args' );

    is( $context->uri_for_action( '/action/chained/endpoint2', [1,2,3,4], { x => 5 } ),
        'http://127.0.0.1/foo/chained/foo2/1/2/end2/3/4?x=5',
        'uri_for_action correct for chained with multiple captures and args combined' );

    is( $context->uri_for_action( '/action/chained/three_end', [1,2,3], (4,5,6) ),
        'http://127.0.0.1/foo/chained/one/1/two/2/3/three/4/5/6',
        'uri_for_action correct for chained with multiple capturing actions' );

    is( $context->uri_for_action( '/action/chained/three_end', [1,2,3,4,5,6] ),
        'http://127.0.0.1/foo/chained/one/1/two/2/3/three/4/5/6',
        'uri_for_action correct for chained with multiple capturing actions and args combined' );

    my $action_needs_two = '/action/chained/endpoint2';

    is( eval { $context->uri_for_action($action_needs_two, [1],     (2,3)) }, undef,
        'uri_for_action returns undef for not enough captures' );

    is( $context->uri_for_action($action_needs_two,            [1,2],   (2,3)),
        'http://127.0.0.1/foo/chained/foo2/1/2/end2/2/3',
        'uri_for_action returns correct uri for correct captures' );

    is( $context->uri_for_action($action_needs_two,            [1,2,2,3]),
        'http://127.0.0.1/foo/chained/foo2/1/2/end2/2/3',
        'uri_for_action returns correct uri for correct captures and args combined' );

    is( eval { $context->uri_for_action($action_needs_two, [1,2,3], (2,3)) }, undef,
        'uri_for_action returns undef for too many captures' );

    is( eval { $context->uri_for_action($action_needs_two, [1,2],   (3)) }, undef,
        'uri_for_action returns uri with lesser args than specified on action' );

    is( eval { $context->uri_for_action($action_needs_two, [1,2,3]) }, undef,
        'uri_for_action returns uri with lesser args than specified on action with captures combined' );

    is( eval { $context->uri_for_action($action_needs_two, [1,2],   (3,4,5)) }, undef,
        'uri_for_action returns uri with more args than specified on action' );

    is( eval { $context->uri_for_action($action_needs_two, [1,2,3,4,5]) }, undef,
        'uri_for_action returns uri with more args than specified on action with captures combined' );

    is( $context->uri_for_action($action_needs_two, [1,''], (3,4)),
        'http://127.0.0.1/foo/chained/foo2/1//end2/3/4',
        'uri_for_action returns uri with empty capture on undef capture' );

    is( $context->uri_for_action($action_needs_two, [1,'',3,4]),
        'http://127.0.0.1/foo/chained/foo2/1//end2/3/4',
        'uri_for_action returns uri with empty capture on undef capture and args combined' );

    is( $context->uri_for_action($action_needs_two, [1,2], ('',3)),
        'http://127.0.0.1/foo/chained/foo2/1/2/end2//3',
        'uri_for_action returns uri with empty arg on undef argument' );

    is( $context->uri_for_action($action_needs_two, [1,2,'',3]),
        'http://127.0.0.1/foo/chained/foo2/1/2/end2//3',
        'uri_for_action returns uri with empty arg on undef argument and args combined' );

    is( $context->uri_for_action($action_needs_two, [1,2], (3,'')),
        'http://127.0.0.1/foo/chained/foo2/1/2/end2/3/',
        'uri_for_action returns uri with empty arg on undef last argument' );

    is( $context->uri_for_action($action_needs_two, [1,2,3,'']),
        'http://127.0.0.1/foo/chained/foo2/1/2/end2/3/',
        'uri_for_action returns uri with empty arg on undef last argument with captures combined' );

    my $complex_chained = '/action/chained/empty_chain_f';
    is( $context->uri_for_action( $complex_chained, [23], (13), {q => 3} ),
        'http://127.0.0.1/foo/chained/empty/23/13?q=3',
        'uri_for_action returns correct uri for chain with many empty path parts' );
    is( $context->uri_for_action( $complex_chained, [23,13], {q => 3} ),
        'http://127.0.0.1/foo/chained/empty/23/13?q=3',
        'uri_for_action returns correct uri for chain with many empty path parts with captures and args combined' );

    eval { $context->uri_for_action( '/does/not/exist' ) };
    like $@, qr{^Can't find action for path '/does/not/exist'},
        'uri_for_action croaks on nonexistent path';

}

done_testing;

