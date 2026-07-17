use v5.36;
use Test::More;
use Test::Fatal;
use Catalyst::Plugin::JSONRPC::Server;
use Catalyst::Plugin::JSONRPC::Server::Dispatcher;

# --- minimal stub context (no Catalyst), with an optional ->config ----------
package StubResponse {
    sub new          { bless {}, shift }
    sub status       { my $s = shift; $s->{status}       = shift if @_; $s->{status} }
    sub content_type { my $s = shift; $s->{content_type} = shift if @_; $s->{content_type} }
    sub body         { my $s = shift; $s->{body}         = shift if @_; $s->{body} }
}
package StubRequest {
    sub new  { my ( $class, $body ) = @_; bless { body => $body }, $class }
    sub body { $_[0]{body} }
}
package StubContext {
    our @ISA = ('Catalyst::Plugin::JSONRPC::Server');
    sub new {
        my ( $class, %args ) = @_;
        bless {
            response => StubResponse->new,
            request  => $args{request},
            ( exists $args{config} ? ( _config => $args{config} ) : () ),
        }, $class;
    }
    sub response { $_[0]{response} }
    sub request  { $_[0]{request} }
    # Only present when a config was supplied, so we also exercise the
    # can('config') guard in the plugin when it is absent.
    sub config   { $_[0]{_config} }
}
# --------------------------------------------------------------------------

# --- I3: handlers registered on one context must NOT leak into another ------
# On the old per-app %DISPATCHER (keyed by app class) a fresh context would see
# a handler a previous context registered; the per-request dispatcher fixes it.
{
    my $c1 = StubContext->new;
    $c1->jsonrpc_register( secret => sub ($p) { 'leaked' } );
    $c1->jsonrpc_dispatch('{"jsonrpc":"2.0","method":"secret","params":[],"id":1}');

    my $c2 = StubContext->new;    # a brand-new request
    my $data = $c2->jsonrpc_dispatch('{"jsonrpc":"2.0","method":"secret","id":2}');
    is( $data->{error}{code}, -32601,
        'a handler registered on one context does not leak into another (I3)' );
}

# --- I4: the nothing-to-send status is configurable (202 for the MCP transport)
{
    my $c = StubContext->new;
    my $d = Catalyst::Plugin::JSONRPC::Server::Dispatcher->new;
    $d->register( note => sub ($p) { 'x' } );
    my $none = $c->jsonrpc_dispatch_with(
        $d, '{"jsonrpc":"2.0","method":"note","params":[1]}', 202 );
    is( $none, undef, 'notification still returns undef' );
    is( $c->response->status, 202,
        'empty-response status honours the caller-supplied 202 (I4)' );
}
# ...and the default is still 204 when not overridden.
{
    my $c = StubContext->new;
    my $d = Catalyst::Plugin::JSONRPC::Server::Dispatcher->new;
    $d->register( note => sub ($p) { 'x' } );
    $c->jsonrpc_dispatch_with( $d, '{"jsonrpc":"2.0","method":"note","params":[1]}' );
    is( $c->response->status, 204, 'empty-response status defaults to 204 (I4)' );
}

# --- I1: a non-serializable handler result must not die at the seam ---------
{
    my $c = StubContext->new;
    $c->jsonrpc_register( obj => sub ($p) { bless {}, 'Foo::Unserializable' } );
    my $data;
    is(
        exception {
            $data = $c->jsonrpc_dispatch('{"jsonrpc":"2.0","method":"obj","id":1}')
        },
        undef,
        'seam does not die on a non-serializable handler result (I1)' );
    is( $c->response->status, 200, 'still HTTP 200' );
    like( $c->response->body, qr/-32603/, 'body carries a -32603 error envelope' );
}

# --- S5: an oversize request body is rejected before parsing ----------------
{
    my $big  = '{"jsonrpc":"2.0","method":"echo","params":["' . ( 'x' x 5000 ) . '"],"id":1}';
    open my $fh, '<', \$big or die "cannot open in-memory fh: $!";
    my $c = StubContext->new(
        request => StubRequest->new($fh),
        config  => { 'Catalyst::Plugin::JSONRPC::Server' => { max_body_bytes => 1000 } },
    );
    $c->jsonrpc_register( echo => sub ($p) { $p } );
    my $data = $c->jsonrpc_dispatch;    # reads the (oversize) body itself
    is( $data->{error}{code}, -32600, 'oversize body rejected with -32600 (S5)' );
    like( $data->{error}{message}, qr/too large/i, 'error names the size problem' );
    is( $c->response->status, 200, 'still a well-formed 200 JSON-RPC error' );
}

# --- S5b: the cap holds when the body comes back as a STRING, not a handle ---
# _jsonrpc_read_body has a `return $body unless ref $body` fast path for configs
# that hand back a decoded string instead of a filehandle. It returned early,
# before the size check, so max_body_bytes only ever fired on the handle branch.
# Catalyst hands back a temp filehandle for POST bodies so this is not the usual
# path, but the cap is documented without qualification.
{
    my $big = '{"jsonrpc":"2.0","method":"echo","params":["' . ( 'x' x 5000 ) . '"],"id":1}';
    my $c   = StubContext->new(
        request => StubRequest->new($big),    # a plain string, not a filehandle
        config  => { 'Catalyst::Plugin::JSONRPC::Server' => { max_body_bytes => 1000 } },
    );
    $c->jsonrpc_register( echo => sub ($p) { $p } );
    my $data = $c->jsonrpc_dispatch;
    is( $data->{error}{code}, -32600, 'oversize string body rejected with -32600 (S5b)' );
}
# ...and an under-cap string body still dispatches normally (the cap must not
# turn into a blanket rejection of the string branch).
{
    my $c = StubContext->new(
        request => StubRequest->new('{"jsonrpc":"2.0","method":"echo","params":["hi"],"id":1}'),
        config  => { 'Catalyst::Plugin::JSONRPC::Server' => { max_body_bytes => 1000 } },
    );
    $c->jsonrpc_register( echo => sub ($p) { $p } );
    my $data = $c->jsonrpc_dispatch;
    is_deeply( $data->{result}, ['hi'], 'an under-cap string body still dispatches (S5b)' );
}

done_testing;
