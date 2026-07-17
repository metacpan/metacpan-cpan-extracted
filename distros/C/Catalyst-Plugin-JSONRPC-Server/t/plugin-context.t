use v5.36;
use Test::More;
use Catalyst::Plugin::JSONRPC::Server;

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

my $c = StubContext->new;
ok( $c->jsonrpc_register( echo => sub ($p) { $p } )->isa('StubContext'),
    'jsonrpc_register returns the context' );

# A normal call: response written + data returned.
my $data = $c->jsonrpc_dispatch('{"jsonrpc":"2.0","method":"echo","params":[1],"id":1}');
is_deeply( $data, { jsonrpc => '2.0', result => [1], id => 1 }, 'returns response data' );
is( $c->response->status, 200, 'status 200' );
is( $c->response->content_type, 'application/json', 'json content type' );
like( $c->response->body, qr/"result":\[1\]/, 'encoded body written' );

# A lone notification: 204, empty body, undef data.
my $c2 = StubContext->new;
$c2->jsonrpc_register( note => sub ($p) { 'x' } );
my $none = $c2->jsonrpc_dispatch('{"jsonrpc":"2.0","method":"note","params":[1]}');
is( $none, undef, 'notification returns undef' );
is( $c2->response->status, 204, 'status 204 for nothing-to-send' );
is( $c2->response->body, '', 'empty body' );

# No-arg dispatch: the plugin reads the raw body from $c->request->body (an
# in-memory filehandle here, an unblessed glob), exercising _jsonrpc_read_body's
# builtin binmode/seek/slurp.
my $json = '{"jsonrpc":"2.0","method":"echo","params":[9],"id":7}';
open my $fh, '<', \$json or die "cannot open in-memory fh: $!";
my $c3 = StubContext->new( request => StubRequest->new($fh) );
$c3->jsonrpc_register( echo => sub ($p) { $p } );
my $d3 = $c3->jsonrpc_dispatch;    # no body arg -> reads request->body
is_deeply( $d3, { jsonrpc => '2.0', result => [9], id => 7 },
    'no-arg dispatch reads and dispatches the raw request body' );
is( $c3->response->status, 200, 'no-arg dispatch wrote status 200' );

done_testing;
