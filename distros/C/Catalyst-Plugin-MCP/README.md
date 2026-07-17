# Catalyst::Plugin::MCP

Generic, app-agnostic Model Context Protocol (revision 2025-06-18) server plugin
for Catalyst, layered on `Catalyst::Plugin::JSONRPC::Server`. It owns the MCP
lifecycle, capability advertisement, and verb routing, and knows nothing about
your domain: you supply providers.

## Synopsis

```perl
package MyApp;
use Catalyst qw/
    +Catalyst::Plugin::JSONRPC::Server
    +Catalyst::Plugin::MCP
/;
__PACKAGE__->setup;

# in a controller action:
sub mcp :Path('/mcp') :Args(0) {
    my ( $self, $c ) = @_;
    $c->mcp_register_provider( $c->model('MCP::Tools') );      # ToolProvider
    $c->mcp_register_provider( $c->model('MCP::Resources') );  # ResourceProvider
    $c->mcp_dispatch;   # reads the body, runs the MCP lifecycle, writes the reply
}
```

## Providers

Implement one of the shipped Moo::Roles per provider object:

- `Catalyst::Plugin::MCP::Role::ResourceProvider`: `list($cursor)`,
  `templates`, `read($uri)`.
- `Catalyst::Plugin::MCP::Role::PromptProvider`: `list($cursor)`,
  `get($name, $args)`.
- `Catalyst::Plugin::MCP::Role::ToolProvider`: `list($cursor)`,
  `call($name, $args)`.

Capabilities advertised in `initialize` are derived from which roles your
registered providers consume. Pagination is pass-through: the cursor flows to
`list($cursor)` and your `nextCursor` flows back out. Tool execution failures
return a normal result with `isError => 1`; unknown tools/prompts/resources and
bad params become JSON-RPC errors (`-32602`, `-32002`).

## Configuration

```perl
__PACKAGE__->config(
    'Catalyst::Plugin::MCP' => {
        protocol_versions => ['2025-06-18'],          # newest-first
        server_info       => { name => 'myapp', version => '1.0' },
    },
);
```

## Security

**This plugin ships no authentication and no `Origin` validation, and
`mcp_dispatch` does not add any.** A `tools/call` runs your provider's code, so
an endpoint mounted as in the synopsis above executes tools for anyone who can
POST to it. Guarding it is the application's job:

- **Authenticate the endpoint.** The MCP Streamable HTTP transport says servers
  SHOULD authenticate connections. Put your own authentication (a Catalyst
  authentication plugin, an `auto` action, or middleware) in front of
  `mcp_dispatch`. Consider also what a provider is allowed to reach: the engine
  does not scope tools or resources to a user.
- **Validate the `Origin` header.** The transport says servers MUST validate
  `Origin`, to stop a browser on another site from driving your endpoint via DNS
  rebinding. Check it against an allow-list and reject anything else before
  dispatching.

Binding to localhost rather than `0.0.0.0` is worth it for a local server, but
it is not a substitute for either of the above. See the `SECURITY` section in
`Catalyst::Plugin::MCP` for detail.

## Author

Mike Whitaker <mike@altrion.org>

Built with tool assistance from Claude Code/(mostly) Opus 4.8 to accelerate
code generation and maximise test coverage (and reduce typing :D).

With thanks to

- Jesse Vincent for `/superpowers` (<https://github.com/obra/superpowers>) and the
  `AGENTS.md` boilerplate
- Curtis "Ovid" Poe for `/paad` (<https://github.com/Ovid/paad>)

for providing an agentic development framework that keeps code authority
firmly where it belongs.

Iteratively reviewed by Finn Kempers <finn@shadow.cat> with analysis from
ZCode/GLM-5.2.

## License

This library is free software; you can redistribute it and/or modify it
under the terms of the Artistic License, as distributed with Perl.
