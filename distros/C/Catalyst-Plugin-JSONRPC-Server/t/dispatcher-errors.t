use v5.36;
use Test::More;
use Test::Fatal;
use JSON::MaybeXS qw/decode_json/;
use Catalyst::Plugin::JSONRPC::Server::Dispatcher;
use Catalyst::Plugin::JSONRPC::Server::Error;

my $d = Catalyst::Plugin::JSONRPC::Server::Dispatcher->new;
$d->register( ok_method => sub ($p) { 'fine' } );
$d->register( boom      => sub ($p) { die "kaboom at secret place\n" } );
$d->register( bad_param => sub ($p) {
    Catalyst::Plugin::JSONRPC::Server::Error->throw(
        code => -32602, message => 'Invalid params' );
} );
$d->register( obj => sub ($p) { bless {}, 'Foo::Unserializable' } );

# -32700 parse error (id is null)
is_deeply( $d->dispatch('this is not json'),
    { jsonrpc => '2.0', error => { code => -32700, message => 'Parse error' }, id => undef },
    'parse error' );

# -32600 not a JSON object
is_deeply( $d->dispatch('"a bare string"'),
    { jsonrpc => '2.0', error => { code => -32600, message => 'Invalid Request' }, id => undef },
    'non-object request is invalid' );

# -32600 wrong jsonrpc version (keeps the id)
is_deeply( $d->dispatch('{"jsonrpc":"1.0","method":"ok_method","id":9}'),
    { jsonrpc => '2.0', error => { code => -32600, message => 'Invalid Request' }, id => 9 },
    'bad jsonrpc version is invalid' );

# -32600 bad params type
is_deeply( $d->dispatch('{"jsonrpc":"2.0","method":"ok_method","params":"x","id":9}'),
    { jsonrpc => '2.0', error => { code => -32600, message => 'Invalid Request' }, id => 9 },
    'scalar params is invalid' );

# -32601 method not found
is_deeply( $d->dispatch('{"jsonrpc":"2.0","method":"nope","id":3}'),
    { jsonrpc => '2.0', error => { code => -32601, message => 'Method not found' }, id => 3 },
    'method not found' );

# handler dies plainly -> -32603, original message NOT leaked
is_deeply( $d->dispatch('{"jsonrpc":"2.0","method":"boom","id":4}'),
    { jsonrpc => '2.0', error => { code => -32603, message => 'Internal error' }, id => 4 },
    'plain die maps to internal error without leaking text' );

# handler throws a structured Error -> its code/message
is_deeply( $d->dispatch('{"jsonrpc":"2.0","method":"bad_param","id":5}'),
    { jsonrpc => '2.0', error => { code => -32602, message => 'Invalid params' }, id => 5 },
    'structured Error maps to its code' );

# --- I2: a structurally-invalid request that happens to lack an id is NOT a
# notification; it must still yield -32600 with id:null (JSON-RPC 2.0 examples).
is_deeply( $d->dispatch('{"foo":"boo"}'),
    { jsonrpc => '2.0', error => { code => -32600, message => 'Invalid Request' }, id => undef },
    'invalid id-less request returns -32600/id:null (not silently dropped)' );
is_deeply( $d->dispatch('[{"foo":"boo"}]'),
    [ { jsonrpc => '2.0', error => { code => -32600, message => 'Invalid Request' }, id => undef } ],
    'invalid id-less batch element yields an error element (not dropped)' );

# --- S1: a structured (array/object) id is invalid; reject with id:null.
is_deeply( $d->dispatch('{"jsonrpc":"2.0","method":"ok_method","id":[1,2]}'),
    { jsonrpc => '2.0', error => { code => -32600, message => 'Invalid Request' }, id => undef },
    'structured id rejected as -32600 with id:null' );

# --- S2: an explicit params:null means "no params", not an invalid request.
is_deeply( $d->dispatch('{"jsonrpc":"2.0","method":"ok_method","params":null,"id":9}'),
    { jsonrpc => '2.0', result => 'fine', id => 9 },
    'params:null is treated as no params, not -32600' );

# --- S3: an oversize batch is rejected (configurable cap).
my $capped = Catalyst::Plugin::JSONRPC::Server::Dispatcher->new( max_batch => 2 );
$capped->register( ok_method => sub ($p) { 'fine' } );
is_deeply(
    $capped->dispatch(
        '[{"jsonrpc":"2.0","method":"ok_method","id":1},'
      . '{"jsonrpc":"2.0","method":"ok_method","id":2},'
      . '{"jsonrpc":"2.0","method":"ok_method","id":3}]'
    ),
    { jsonrpc => '2.0', error => { code => -32600, message => 'Batch too large' }, id => undef },
    'batch beyond max_batch is rejected' );

# --- I1: a non-serializable handler result must NOT blow up encoding. Plain
# encode() dies; encode_safe() degrades the offending element to -32603 (id kept).
my $obj_resp = $d->dispatch('{"jsonrpc":"2.0","method":"obj","id":8}');
ok( exception { $d->encode($obj_resp) },
    'plain encode dies on a non-serializable result' );
is_deeply(
    decode_json( $d->encode_safe($obj_resp) ),
    { jsonrpc => '2.0', error => { code => -32603, message => 'Internal error' }, id => 8 },
    'encode_safe degrades a non-serializable result to -32603 (id preserved)' );
is_deeply(
    decode_json( $d->encode_safe( $d->dispatch(
        '[{"jsonrpc":"2.0","method":"ok_method","id":1},'
      . '{"jsonrpc":"2.0","method":"obj","id":2}]'
    ) ) ),
    [ { jsonrpc => '2.0', result => 'fine', id => 1 },
      { jsonrpc => '2.0', error => { code => -32603, message => 'Internal error' }, id => 2 } ],
    'encode_safe salvages only the bad element of a batch' );

done_testing;
