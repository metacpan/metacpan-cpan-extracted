use v5.36;
use Test::More;
use Test::Fatal;
use Catalyst::Plugin::JSONRPC::Server::Dispatcher;

my $d = Catalyst::Plugin::JSONRPC::Server::Dispatcher->new;
ok( $d->register( echo => sub ($params) { return $params } )
        ->isa('Catalyst::Plugin::JSONRPC::Server::Dispatcher'),
    'register() is chainable' );

# Positional params
my $res = $d->dispatch( '{"jsonrpc":"2.0","method":"echo","params":[1,2,3],"id":1}' );
is_deeply( $res,
    { jsonrpc => '2.0', result => [ 1, 2, 3 ], id => 1 },
    'single request returns a result envelope' );

# Named params + string id
$d->register( add => sub ($p) { $p->{a} + $p->{b} } );
my $res2 = $d->dispatch(
    '{"jsonrpc":"2.0","method":"add","params":{"a":2,"b":5},"id":"abc"}' );
is_deeply( $res2, { jsonrpc => '2.0', result => 7, id => 'abc' },
    'named params, string id' );

# No params at all
$d->register( ping => sub ($p) { 'pong' } );
my $res3 = $d->dispatch( '{"jsonrpc":"2.0","method":"ping","id":2}' );
is_deeply( $res3, { jsonrpc => '2.0', result => 'pong', id => 2 }, 'params optional' );

# Falsy ids are ids. The spec distinguishes a request from a notification by the
# PRESENCE of id, not its truth, so 0 and "" must round-trip as ids rather than
# be mistaken for absent. Pins !exists/!ref against a future truthiness check.
$d->register( zero => sub ($p) { 'ok' } );
is_deeply( $d->dispatch( '{"jsonrpc":"2.0","method":"zero","id":0}' ),
    { jsonrpc => '2.0', result => 'ok', id => 0 }, 'id 0 is a request, not a notification' );
is_deeply( $d->dispatch( '{"jsonrpc":"2.0","method":"zero","id":""}' ),
    { jsonrpc => '2.0', result => 'ok', id => '' }, 'empty-string id is a request' );

# encode() round-trips a response to canonical JSON
like( $d->encode( { jsonrpc => '2.0', result => 1, id => 1 } ),
    qr/"jsonrpc":"2\.0"/, 'encode() produces JSON text' );

# register() input validation
like( exception { $d->register( '', sub { } ) },
    qr/non-empty string/, 'empty method name dies' );
like( exception { $d->register( 'x', 'notcode' ) },
    qr/CODE ref/, 'non-coderef handler dies' );

done_testing;
