# Catalyst::Plugin::JSONRPC::Server

Generic, app-agnostic JSON-RPC 2.0 server plugin for Catalyst. It implements the
protocol (envelope parsing, single + batch, notifications, the standard error
codes) and knows nothing about your domain.

## Synopsis

```perl
package MyApp;
use Catalyst qw/+Catalyst::Plugin::JSONRPC::Server/;
__PACKAGE__->setup;

# in a controller action:
sub rpc :Path('/rpc') :Args(0) {
    my ( $self, $c ) = @_;
    $c->jsonrpc_register( add => sub ($params) { $params->{a} + $params->{b} } );
    $c->jsonrpc_dispatch;   # reads the raw request body itself
}
```

## Methods

- `$c->jsonrpc_register($method => $coderef)`: register a handler. The handler
  is called as `$coderef->($params)`; return the result, or throw a
  `Catalyst::Plugin::JSONRPC::Server::Error` (or `die` with `{ code, message,
  data }`) to return a JSON-RPC error. A plain `die` becomes `-32603` without
  leaking the message.
- `$c->jsonrpc_dispatch($body = undef)`: dispatch a JSON-RPC request. Pass the
  raw body, or omit it to have the plugin read the raw request body. Writes the
  HTTP response (200 + JSON, or 204 for a notification) and returns the data.

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
