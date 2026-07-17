use v5.36;
use Test::More;
use JSON::MaybeXS qw/decode_json/;
use Catalyst::Plugin::MCP;
use Catalyst::Plugin::JSONRPC::Server;

# Regression test: I1, per-request dispatcher isolation
#
# Under the OLD shared-dispatcher code, mcp_dispatch called
# $c->jsonrpc_register(...) for each request's handlers, writing them onto
# the persistent per-application Dispatcher.  A first request registering
# both tools and resources would install "resources/read" on that shared
# dispatcher; a later request from the same app class that registered tools
# only would still see "resources/read" route to the first request's engine,
# returning a result instead of a -32601 error.
#
# The fix: mcp_dispatch now builds a fresh
# Catalyst::Plugin::JSONRPC::Server::Dispatcher per request and dispatches
# via jsonrpc_dispatch_with(), so only the current request's handlers exist.

# --- minimal stub context (copied from plugin-context.t) -----------------
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

# --- stubs ---------------------------------------------------------------
package StubTools {
    use Moo;
    with 'Catalyst::Plugin::MCP::Role::ToolProvider';
    sub list ( $self, $cursor = undef ) {
        return { tools => [ { name => 'echo' } ] };
    }
    sub call ( $self, $name, $args ) {
        return { content => [ { type => 'text', text => "ran $name" } ] };
    }
}

package StubResources {
    use Moo;
    with 'Catalyst::Plugin::MCP::Role::ResourceProvider';
    sub list ( $self, $cursor = undef ) {
        return { resources => [ { uri => 'res://foo', name => 'foo' } ] };
    }
    sub templates ( $self ) {
        return { resourceTemplates => [] };
    }
    sub read ( $self, $uri ) {
        # Return something non-undef so that, if handler leakage existed,
        # the dispatcher would return a successful result rather than -32601,
        # making this test a true discriminator.
        return { contents => [ { uri => $uri, text => 'leaked content' } ] };
    }
}
# -------------------------------------------------------------------------

# Request 1: registers BOTH tools and resources, dispatches initialize.
# Under old code this would write "resources/list", "resources/templates",
# and "resources/read" onto the shared per-app dispatcher.
my $c1 = StubContext->new(
    body => '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2025-06-18"},"id":1}',
);
$c1->mcp_register_provider( StubTools->new );
$c1->mcp_register_provider( StubResources->new );
my $r1 = $c1->mcp_dispatch;
is( $c1->response->status, 200, 'request 1: initialize returns 200' );
ok( defined $r1->{result}, 'request 1: got a result' );

# Request 2: SAME class (StubContext), so it shares the per-app dispatcher
# key.  Registers tools ONLY, no ResourceProvider.
# Then dispatches "resources/read"; this verb was NEVER registered for this
# request, so the response must be -32601 (method not found).
my $c2 = StubContext->new(
    body => '{"jsonrpc":"2.0","method":"resources/read","params":{"uri":"x"},"id":9}',
);
$c2->mcp_register_provider( StubTools->new );    # tools only, no resources
my $r2 = $c2->mcp_dispatch;
is( $c2->response->status, 200,
    'request 2: HTTP 200 (JSON-RPC errors still use 200)' );
is( $r2->{error}{code}, -32601,
    'request 2: resources/read is method-not-found, no verb leakage from request 1' );

done_testing;
