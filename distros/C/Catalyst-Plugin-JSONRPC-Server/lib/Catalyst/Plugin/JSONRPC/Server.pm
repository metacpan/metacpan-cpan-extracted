package Catalyst::Plugin::JSONRPC::Server;
use v5.36;
use Catalyst::Plugin::JSONRPC::Server::Dispatcher;

our $VERSION = '0.004';

=encoding utf8

=head1 NAME

Catalyst::Plugin::JSONRPC::Server - Generic JSON-RPC 2.0 server plugin for Catalyst

=head1 SYNOPSIS

    package MyApp;
    use Catalyst qw/+Catalyst::Plugin::JSONRPC::Server/;
    __PACKAGE__->setup;

    sub rpc :Path('/rpc') :Args(0) {
        my ( $self, $c ) = @_;
        $c->jsonrpc_register( add => sub ($params) { $params->{a} + $params->{b} } );
        $c->jsonrpc_dispatch;
    }

=head1 DESCRIPTION

Adds JSON-RPC 2.0 request dispatch to a Catalyst application. The protocol
engine lives in L<Catalyst::Plugin::JSONRPC::Server::Dispatcher>; this module is
the thin Catalyst seam: it adds C<jsonrpc_register> and C<jsonrpc_dispatch> to
the context.

The dispatcher used by C<jsonrpc_register>/C<jsonrpc_dispatch> is built fresh for
each request and cached on the context, so handlers (and anything they close
over, such as C<$c>) never leak into a later request. It is therefore safe to
register handlers inside a request action, as the SYNOPSIS does.

=head1 CONFIGURATION

Under the C<'Catalyst::Plugin::JSONRPC::Server'> config key:

=over 4

=item C<max_body_bytes>

Maximum raw request body size the plugin will read (default 10 MiB; C<0> =
unlimited). A larger body is rejected with a C<-32600> "Request too large".

=back

The per-request dispatcher's C<max_batch> (maximum batch-array length, default
1000; C<0> = unlimited) is a
L<Catalyst::Plugin::JSONRPC::Server::Dispatcher> attribute; supply your own
dispatcher via
L<< C<jsonrpc_dispatch_with>|/"jsonrpc_dispatch_with( $dispatcher, $body =
undef, $empty_status = 204 )" >> to change it.

=cut

# Default cap on the raw request body (bytes); 0 = unlimited. Overridable per app
# via $c->config->{'Catalyst::Plugin::JSONRPC::Server'}{max_body_bytes}.
my $DEFAULT_MAX_BODY_BYTES = 10 * 1024 * 1024;

# Per-request dispatcher: built fresh for each request and cached on the context
# object, so handlers (and anything they close over, such as $c) never leak into
# a later request served by the same worker. Re-registering a method name within
# a request is idempotent.
sub _jsonrpc_dispatcher ( $c ) {
    return $c->{'__jsonrpc_dispatcher'}
        //= Catalyst::Plugin::JSONRPC::Server::Dispatcher->new;
}

sub jsonrpc_register ( $c, $method, $code ) {
    $c->_jsonrpc_dispatcher->register( $method, $code );
    return $c;
}

sub jsonrpc_dispatch ( $c, $body = undef ) {
    return $c->jsonrpc_dispatch_with( $c->_jsonrpc_dispatcher, $body );
}

sub jsonrpc_dispatch_with ( $c, $dispatcher, $body = undef, $empty_status = 204 ) {
    my $res = $c->response;

    # When we read the body ourselves, an oversize body comes back as a scalar
    # ref sentinel; reject it before parsing. A caller-supplied $body (a string)
    # is the caller's responsibility and is not size-checked here.
    my $read = $body // $c->_jsonrpc_read_body;
    if ( ref $read ) {
        return $c->_jsonrpc_write( $dispatcher, {
            jsonrpc => '2.0',
            error   => { code => -32600, message => 'Request too large' },
            id      => undef,
        }, 200 );
    }

    my $data = $dispatcher->dispatch($read);

    if ( !defined $data ) {
        $res->status($empty_status);
        $res->body(q{});
        return undef;
    }
    return $c->_jsonrpc_write( $dispatcher, $data, 200 );
}

sub _jsonrpc_write ( $c, $dispatcher, $data, $status ) {
    my $res = $c->response;
    $res->status($status);
    $res->content_type('application/json');
    # encode_safe: a handler result that won't serialize degrades to a -32603
    # here rather than dying (outside any try) and turning into an HTTP 500.
    $res->body( $dispatcher->encode_safe($data) );
    return $data;
}

sub _jsonrpc_max_body_bytes ( $c ) {
    return $DEFAULT_MAX_BODY_BYTES unless $c->can('config');
    my $conf = $c->config or return $DEFAULT_MAX_BODY_BYTES;
    my $cfg = $conf->{'Catalyst::Plugin::JSONRPC::Server'} || {};
    return $cfg->{max_body_bytes} // $DEFAULT_MAX_BODY_BYTES;
}

# Read the raw (undecoded) request body. Catalyst buffers it; $c->request->body
# is a (usually seekable) filehandle for content types it does not parse (e.g.
# application/json). Returns '' when there is no body, or a scalar ref sentinel
# when the body exceeds the configured size cap. We use the builtin binmode/seek
# (not method calls) so this works on both blessed IO objects and plain glob
# filehandles; binmode guarantees raw bytes, which the Dispatcher's utf8 codec
# expects.
sub _jsonrpc_read_body ( $c ) {
    my $body = $c->request->body;
    return q{} unless defined $body;
    my $limit = $c->_jsonrpc_max_body_bytes;

    # Some configs hand back a string rather than a filehandle. The cap applies
    # to every body we read ourselves, not just the filehandle branch, so this
    # is size-checked too (a caller-supplied body stays the caller's problem --
    # see jsonrpc_dispatch_with). Bodies are raw bytes by contract, so length()
    # is the byte count.
    unless ( ref $body ) {
        return \'too_large' if $limit && length($body) > $limit;
        return $body;
    }

    binmode $body;                          # raw bytes (codec does the utf8 decode)
    if ($limit) {
        seek $body, 0, 2;                    # SEEK_END: size it without slurping
        my $size = tell $body;
        if ( defined $size && $size > $limit ) {
            seek $body, 0, 0;
            return \'too_large';             # sentinel: caller emits -32600
        }
    }
    seek $body, 0, 0;                        # rewind (Catalyst may have read it)
    local $/ = undef;                        # slurp mode
    my $content = <$body>;
    return defined $content ? $content : q{};
}

=head1 METHODS

=head2 jsonrpc_register( $method => $coderef )

Register a handler for a JSON-RPC method name. The handler is invoked as
C<< $coderef->($params) >>, where C<$params> is the request's C<params>
(an arrayref, hashref, or undef). Return the result; to signal a JSON-RPC
error, throw a L<Catalyst::Plugin::JSONRPC::Server::Error> (or C<die> with a
C<< { code, message, data } >> hashref). A plain C<die> becomes a C<-32603>
internal error whose text is not leaked. Returns C<$c> (chainable).

=head2 jsonrpc_dispatch( $body = undef )

Dispatch a JSON-RPC 2.0 request. Pass the raw JSON body, or omit it to have the
plugin read the raw request body from C<< $c->request->body >>. Writes the HTTP
response (200 with the JSON envelope for a result or error, or 204 with an
empty body when there is nothing to send, i.e. a notification) and returns the
response data (hashref or arrayref) or C<undef>.

Delegates to
L<< C<jsonrpc_dispatch_with>|/"jsonrpc_dispatch_with( $dispatcher, $body =
undef, $empty_status = 204 )" >> using the per-request dispatcher.

=head2 jsonrpc_dispatch_with( $dispatcher, $body = undef, $empty_status = 204 )

Like C<jsonrpc_dispatch>, but dispatches against a caller-supplied
L<Catalyst::Plugin::JSONRPC::Server::Dispatcher>. Use this when you want to
control the dispatcher yourself, e.g. to pre-register a fixed handler set once,
or to set a non-default C<max_batch>. (A consumer such as an MCP plugin builds a
fresh per-request dispatcher and dispatches it here.)

C<$dispatcher> must be a L<Catalyst::Plugin::JSONRPC::Server::Dispatcher>
instance. C<$body> is the raw JSON string; when omitted the plugin reads the raw
request body from C<< $c->request->body >> (subject to C<max_body_bytes>).
C<$empty_status> is the HTTP status used when there is nothing to send (a
notification or all-notification batch); it defaults to C<204>, but a transport
that requires a different code (e.g. MCP's Streamable HTTP, which mandates
C<202 Accepted>) can pass it. Writes the HTTP response and returns the response
data (hashref or arrayref) or C<undef>. A handler result that will not serialize
degrades to a C<-32603> error rather than dying (see
L<Catalyst::Plugin::JSONRPC::Server::Dispatcher/encode_safe>).

=head1 EXAMPLES

A runnable example lives in F<examples/>: a small Catalyst app exposing C<echo>
and C<sum> over JSON-RPC, plus a core-Perl client. Start it with
C<plackup examples/app.psgi> and run C<perl examples/client.pl>. See
F<examples/README.md>.

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
