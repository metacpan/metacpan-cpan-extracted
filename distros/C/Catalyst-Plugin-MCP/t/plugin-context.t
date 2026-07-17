use v5.36;
use Test::More;
use JSON::MaybeXS qw/decode_json/;
use Catalyst::Plugin::MCP;
use Catalyst::Plugin::JSONRPC::Server;

# --- minimal stub context (no Catalyst) ---------------------------------
package StubResponse {
    sub new          { bless {}, shift }
    sub status       { my $s = shift; $s->{status}       = shift if @_; $s->{status} }
    sub content_type { my $s = shift; $s->{content_type} = shift if @_; $s->{content_type} }
    sub body         { my $s = shift; $s->{body}         = shift if @_; $s->{body} }
}
package StubRequest {
    sub new  { my ( $c, $body ) = @_; bless { body => $body }, $c }
    sub body { $_[0]{body} }
}
package StubContext {
    our @ISA = ( 'Catalyst::Plugin::MCP', 'Catalyst::Plugin::JSONRPC::Server' );
    sub new {
        my ( $class, %a ) = @_;
        bless {
            response => StubResponse->new,
            request  => StubRequest->new( $a{body} ),
            stash    => {},
            config   => $a{config} // {},
        }, $class;
    }
    sub response { $_[0]{response} }
    sub request  { $_[0]{request} }
    sub stash    { $_[0]{stash} }
    sub config   { $_[0]{config} }
}
package StubTools {
    use Moo;
    with 'Catalyst::Plugin::MCP::Role::ToolProvider';
    sub list ( $self, $cursor = undef ) { return { tools => [ { name => 'echo' } ] } }
    sub call ( $self, $name, $args )    { return { content => [ { type => 'text', text => "ran $name" } ] } }
}
# ------------------------------------------------------------------------

# initialize over the stub: response written, capabilities advertised
my $c = StubContext->new(
    body => '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2025-06-18"},"id":1}',
);
ok( $c->mcp_register_provider( StubTools->new )->isa('StubContext'),
    'mcp_register_provider returns the context' );
my $data = $c->mcp_dispatch;
is( $c->response->status, 200, 'status 200' );
is( $data->{result}{protocolVersion}, '2025-06-18', 'initialize negotiated' );
is_deeply( $data->{result}{capabilities}, { tools => {} },
    'capabilities advertised from provider' );

# tools/call routes through to the provider
my $c2 = StubContext->new(
    body => '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"echo"},"id":2}',
);
$c2->mcp_register_provider( StubTools->new );
my $r2 = $c2->mcp_dispatch;
is_deeply( $r2->{result}, { content => [ { type => 'text', text => 'ran echo' } ] },
    'tools/call routed to provider over the plugin seam' );

# a verb whose kind was never registered -> JSON-RPC -32601 method not found
my $c3 = StubContext->new(
    body => '{"jsonrpc":"2.0","method":"prompts/list","id":3}',
);
$c3->mcp_register_provider( StubTools->new );    # tools only
my $r3 = $c3->mcp_dispatch;
is( $r3->{error}{code}, -32601, 'unregistered kind verb is method-not-found' );

done_testing;
