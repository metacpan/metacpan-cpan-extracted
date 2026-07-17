use v5.36;
use Test::More;
use Catalyst::Plugin::JSONRPC::Server;
use Catalyst::Plugin::JSONRPC::Server::Dispatcher;

# --- minimal stub context (no Catalyst, no Moo) ---------------------------
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
    # Inherit the plugin's $c->jsonrpc_* methods via plain @ISA - the same way
    # Catalyst composes a plugin. No Moo/extends involved.
    our @ISA = ('Catalyst::Plugin::JSONRPC::Server');
    sub new {
        my ( $class, %args ) = @_;
        bless { response => StubResponse->new, request => $args{request} }, $class;
    }
    sub response { $_[0]{response} }
    sub request  { $_[0]{request} }
}
# --------------------------------------------------------------------------

# Test 1: jsonrpc_dispatch_with dispatches against the PASSED dispatcher.
# The caller-built dispatcher has an 'echo' handler; the per-app dispatcher
# does not. We verify 200 + correct JSON + correct return value.
{
    my $caller_disp = Catalyst::Plugin::JSONRPC::Server::Dispatcher->new;
    $caller_disp->register( echo => sub ($p) { $p } );

    my $c = StubContext->new;
    # Deliberately do NOT register 'echo' on the per-app dispatcher.

    my $data = $c->jsonrpc_dispatch_with(
        $caller_disp,
        '{"jsonrpc":"2.0","method":"echo","params":["hello"],"id":1}',
    );

    is_deeply( $data, { jsonrpc => '2.0', result => ['hello'], id => 1 },
        'dispatch_with: returns response data from caller dispatcher' );
    is( $c->response->status, 200, 'dispatch_with: status 200' );
    is( $c->response->content_type, 'application/json',
        'dispatch_with: json content type' );
    like( $c->response->body, qr/"result":\["hello"\]/,
        'dispatch_with: encoded body written' );
}

# Test 2: per-app dispatcher is NOT consulted by jsonrpc_dispatch_with.
# Register 'only_in_app' on the per-app dispatcher via $c->jsonrpc_register.
# Pass a SEPARATE dispatcher (with no handlers) to jsonrpc_dispatch_with.
# Expect a -32601 method-not-found error response (isolation confirmed).
{
    my $c = StubContext->new;
    $c->jsonrpc_register( only_in_app => sub ($p) { 'should never run' } );

    my $sep_disp = Catalyst::Plugin::JSONRPC::Server::Dispatcher->new;
    # sep_disp intentionally has NO handlers registered.

    my $data = $c->jsonrpc_dispatch_with(
        $sep_disp,
        '{"jsonrpc":"2.0","method":"only_in_app","id":1}',
    );

    ok( defined $data, 'dispatch_with isolation: got a response (not undef)' );
    is( $data->{error}{code}, -32601,
        'dispatch_with isolation: -32601 method not found (per-app dispatcher not consulted)' );
    is( $c->response->status, 200,
        'dispatch_with isolation: status 200 (error still returns JSON envelope)' );
}

# Test 3: a notification (no id) through jsonrpc_dispatch_with yields 204 + empty body.
{
    my $caller_disp = Catalyst::Plugin::JSONRPC::Server::Dispatcher->new;
    $caller_disp->register( note => sub ($p) { 'x' } );

    my $c = StubContext->new;

    my $none = $c->jsonrpc_dispatch_with(
        $caller_disp,
        '{"jsonrpc":"2.0","method":"note","params":[1]}',
    );

    is( $none, undef, 'dispatch_with notification: returns undef' );
    is( $c->response->status, 204,
        'dispatch_with notification: status 204' );
    is( $c->response->body, '',
        'dispatch_with notification: empty body' );
}

done_testing;
