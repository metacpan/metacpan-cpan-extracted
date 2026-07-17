package Catalyst::Plugin::MCP;
use v5.36;
use Catalyst::Plugin::MCP::Server;
use Catalyst::Plugin::JSONRPC::Server::Dispatcher;

our $VERSION = '0.003';

my $PROVIDER_SLOT = 'Catalyst::Plugin::MCP/providers';

sub mcp_register_provider ( $c, $obj ) {
    my $list = $c->stash->{$PROVIDER_SLOT} //= [];
    push @$list, $obj;
    return $c;
}

sub mcp_dispatch ( $c, $body = undef ) {
    my $providers = $c->stash->{$PROVIDER_SLOT} // [];
    my $cfg       = $c->config->{'Catalyst::Plugin::MCP'} // {};

    my %args;
    $args{protocol_versions} = $cfg->{protocol_versions}
        if $cfg->{protocol_versions};
    $args{server_info} = $cfg->{server_info} if $cfg->{server_info};

    my $engine = Catalyst::Plugin::MCP::Server->new(%args);
    $engine->register_provider($_) for @$providers;

    my $handlers = $engine->handlers;

    # Build a fresh per-request dispatcher so each request's verb set is
    # isolated: no stale verbs from prior requests leak across, and there
    # are no cross-thread races on the shared per-application dispatcher.
    my $dispatcher = Catalyst::Plugin::JSONRPC::Server::Dispatcher->new;
    $dispatcher->register( $_ => $handlers->{$_} ) for keys %$handlers;

    # MCP's Streamable HTTP transport requires HTTP 202 Accepted (not the
    # generic JSON-RPC 204) for a POST that carries only responses/notifications,
    # i.e. when the dispatcher has nothing to send back.
    return $c->jsonrpc_dispatch_with( $dispatcher, $body, 202 );
}

=head1 NAME

Catalyst::Plugin::MCP - Model Context Protocol server plugin for Catalyst

=head1 SYNOPSIS

    package MyApp;
    use Catalyst qw/
        +Catalyst::Plugin::JSONRPC::Server
        +Catalyst::Plugin::MCP
    /;
    __PACKAGE__->setup;

    # in a controller action mounted at your MCP endpoint
    sub mcp :Path('/mcp') :Args(0) {
        my ( $self, $c ) = @_;
        $c->mcp_register_provider( $c->model('MCP::Resources') );
        $c->mcp_register_provider( $c->model('MCP::Tools') );
        $c->mcp_dispatch;
    }

=head1 REQUIRED PLUGINS

This plugin builds on L<Catalyst::Plugin::JSONRPC::Server> and calls its
C<jsonrpc_dispatch_with> method. The consuming application B<must> load
C<Catalyst::Plugin::JSONRPC::Server> in its plugin list, B<before>
C<Catalyst::Plugin::MCP> (as in the SYNOPSIS). Declaring the distribution as a
prerequisite installs it but does not load it into the application class: a
Catalyst plugin is only mixed into C<$c> when listed in C<use Catalyst
qw/+.../>. Omitting it yields a runtime C<< Can't locate object method
"jsonrpc_dispatch_with" >> at the first MCP request.

=head1 DESCRIPTION

Adds a Model Context Protocol (revision 2025-06-18) server to a Catalyst
application, layered on L<Catalyst::Plugin::JSONRPC::Server>. The protocol
engine lives in L<Catalyst::Plugin::MCP::Server>; this module is the thin
Catalyst seam.

Each call to C<mcp_dispatch> builds a fresh
L<Catalyst::Plugin::JSONRPC::Server::Dispatcher> containing only the handlers
registered by the providers in the current request's stash. The shared
per-application dispatcher provided by C<Catalyst::Plugin::JSONRPC::Server>
is never written to by this plugin, so there is no cross-request verb leakage
and no concurrency hazard between simultaneous requests.

=head1 METHODS

=head2 mcp_register_provider( $obj )

Add a provider object to the current request's provider set. C<$obj> must be
blessed and must consume at least one of the provider roles
(L<Catalyst::Plugin::MCP::Role::ResourceProvider>,
L<Catalyst::Plugin::MCP::Role::PromptProvider>,
L<Catalyst::Plugin::MCP::Role::ToolProvider>); one provider per kind. Returns
C<$c>, so calls chain.

Providers are validated when C<mcp_dispatch> builds the engine, not here, so a
bad provider dies at dispatch. Registration is per-request (it lives in the
stash), so each request must register its own providers.

=head2 mcp_dispatch( $body )

Run the MCP request: build an engine from the registered providers and config,
route the verb, and write the response. Call it last in the action.

C<$body> is optional. Omit it and the request body is read and size-checked for
you, which is what you want. Pass a raw (still-encoded) JSON string only if you
have already consumed the body yourself. A supplied C<$body> bypasses
L<Catalyst::Plugin::JSONRPC::Server>'s oversize check, which makes the size
limit your problem.

A POST carrying only notifications or responses has no reply to send, and gets
HTTP 202 with an empty body as the Streamable HTTP transport requires.

=head1 CONFIGURATION

Under the C<Catalyst::Plugin::MCP> key; both are optional and are passed to
L<Catalyst::Plugin::MCP::Server/new>:

    __PACKAGE__->config(
        'Catalyst::Plugin::MCP' => {
            protocol_versions => ['2025-06-18'],
            server_info       => { name => 'myapp', version => '1.0' },
        },
    );

=over

=item protocol_versions

Supported MCP revisions, newest-first. The first is preferred, and is what a
client gets when it asks for a version you do not support.

=item server_info

Advertised at C<initialize>. Defaults to a generic name and this plugin's
version, so set it to your own.

=back

=head1 SECURITY

B<This plugin ships no authentication and no C<Origin> validation, and
C<mcp_dispatch> does not add any.> A C<tools/call> runs your provider's code,
so an endpoint mounted as in the SYNOPSIS executes tools for anyone who can
POST to it. Guarding it is the application's job, and both of these are on you:

=over

=item Authenticate the endpoint

The MCP Streamable HTTP transport says servers SHOULD authenticate connections.
Put your own authentication (a Catalyst authentication plugin, an C<auto>
action, or middleware) in front of C<mcp_dispatch>, and let the request reach it
only once it is authorised. Consider also what a provider is allowed to reach:
the engine does not scope tools or resources to a user.

=item Validate the C<Origin> header

The transport says servers MUST validate C<Origin> on incoming connections, to
stop a browser on another site from driving your endpoint via DNS rebinding.
Check it against an allow-list and reject anything else before dispatching.

=back

Binding to localhost rather than C<0.0.0.0> is worth it for a local server, but
it is not a substitute for either of the above.

=head1 EXAMPLES

A runnable example lives in F<examples/>: a small Catalyst app loading
C<Catalyst::Plugin::JSONRPC::Server> then C<Catalyst::Plugin::MCP>, mounting
an C<echo> tool and a static resource at C</mcp>, plus a core-Perl client that
replays the C<initialize> / C<tools/list> / C<tools/call> / C<resources/read>
handshake. Start it with C<plackup examples/app.psgi> and run C<perl
examples/client.pl>. See F<examples/README.md>.

=head1 AUTHOR

Mike Whitaker <mike@altrion.org>

Built with tool assistance from Claude Code/(mostly) Opus 4.8 to accelerate
code generation and maximise test coverage (and reduce typing :D).

With thanks to

=over

=item *

Jesse Vincent for C</superpowers> (L<https://github.com/obra/superpowers>) and
the C<AGENTS.md> boilerplate

=item *

Curtis "Ovid" Poe for C</paad> (L<https://github.com/Ovid/paad>)

=back

for providing an agentic development framework that keeps code authority
firmly where it belongs.

Iteratively reviewed by Finn Kempers <finn@shadow.cat> with analysis from
ZCode/GLM-5.2.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the terms of the Artistic License, as distributed with Perl.

=cut

1;
