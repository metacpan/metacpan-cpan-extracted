package Claude::Agent::MCP::SDKBridge;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Future;
use Claude::Agent::Logger '$log';

BEGIN {
    Object::Proto::define('Claude::Agent::MCP::SDKBridge',
        'server:required',
        'loop:predicate',
        'tool_timeout:Num:predicate',
    );
}

my $PROTOCOL_VERSION = '2024-11-05';

sub handle {
    my ($self, $message) = @_;

    return Future->done($self->_error(undef, -32600, 'Invalid request'))
        unless ref $message eq 'HASH';

    my $method = $message->{method} // '';
    my $id     = $message->{id};
    my $params = ref $message->{params} eq 'HASH' ? $message->{params} : {};

    return Future->done(undef) if $method =~ m{^notifications/};
    return Future->done(undef) if !length $method;

    $log->debug(sprintf("SDKBridge: %s %s", $self->server->name, $method));

    if ($method eq 'initialize') {
        return Future->done($self->_result($id, {
            protocolVersion => $params->{protocolVersion} // $PROTOCOL_VERSION,
            capabilities    => { tools => {} },
            serverInfo      => {
                name    => $self->server->name,
                version => $self->server->version,
            },
        }));
    }
    if ($method eq 'ping') {
        return Future->done($self->_result($id, {}));
    }
    if ($method eq 'tools/list') {
        return Future->done($self->_result($id, {
            tools => [ map { $_->to_hash } @{$self->server->tools} ],
        }));
    }
    if ($method eq 'tools/call') {
        return $self->_call($id, $params);
    }
    return Future->done($self->_error($id, -32601, "Method not found: $method"));
}

sub _call {
    my ($self, $id, $params) = @_;

    my $name = $params->{name};
    my $tool = $self->server->get_tool($name)
        or return Future->done($self->_error($id, -32601, 'Unknown tool: ' . _safe($name)));

    my $args = ref $params->{arguments} eq 'HASH' ? $params->{arguments} : {};
    my $loop = $self->has_loop ? $self->loop : undef;

    my $future = $tool->execute($args, $loop);

    if ($loop && !$future->is_ready) {
        my $timeout = $self->timeout_seconds;
        $future = Future->wait_any(
            $future,
            $loop->timeout_future(after => $timeout)->else(sub {
                $log->debug(sprintf("SDKBridge: tool %s timed out after %ss", $name, $timeout));
                return Future->done({
                    content  => [{ type => 'text', text => "Tool $name timed out after ${timeout}s" }],
                    is_error => 1,
                });
            }),
        );
    }

    return $future->then(sub {
        my ($result) = @_;
        my $valid = ref $result eq 'HASH' && ref $result->{content} eq 'ARRAY';
        if ($valid) {
            for my $block (@{$result->{content}}) {
                next if ref $block eq 'HASH' && defined $block->{type};
                $valid = 0;
                last;
            }
        }
        $result = {
            content  => [{ type => 'text', text => 'Invalid handler result format' }],
            is_error => 1,
        } unless $valid;
        for my $block (@{$result->{content}}) {
            $block->{text} = "$block->{text}" if defined $block->{text} && !ref $block->{text};
        }
        return Future->done($self->_result($id, {
            content => $result->{content},
            isError => $result->{is_error} ? \1 : \0,
        }));
    })->else(sub {
        my ($error) = @_;
        return Future->done($self->_error($id, -32603, _safe($error // 'Internal error')));
    });
}

sub timeout_seconds {
    my ($self) = @_;
    return $self->tool_timeout if $self->has_tool_timeout;
    my $timeout = $ENV{CLAUDE_AGENT_TOOL_TIMEOUT} // 60;
    return 60 if $timeout !~ /^\d+$/ || $timeout < 1;
    return 300 if $timeout > 300;
    return $timeout;
}

sub _result {
    my ($self, $id, $result) = @_;
    return { jsonrpc => '2.0', id => $id, result => $result };
}

sub _error {
    my ($self, $id, $code, $message) = @_;
    return { jsonrpc => '2.0', id => $id, error => { code => $code, message => $message } };
}

sub _safe {
    my ($text) = @_;
    $text = defined $text ? "$text" : '';
    $text = substr($text, 0, 200);
    $text =~ s/[[:cntrl:]]//g;
    return $text;
}

1;

__END__

=head1 NAME

Claude::Agent::MCP::SDKBridge - Answer the CLI's MCP requests for an in-process server

=head1 SYNOPSIS

    my $bridge = Claude::Agent::MCP::SDKBridge->new(
        server => $sdk_server,
        loop   => $loop,
    );

    my $reply = $bridge->handle($jsonrpc_message)->get;

=head1 DESCRIPTION

When an L<Claude::Agent::MCP::Server> is listed in C<mcp_servers>, the CLI
is told it is an C<sdk> server and sends every MCP request for it back to
the SDK as a C<mcp_message> control request. L<Claude::Agent::Query> hands
the JSON-RPC message to this bridge and writes the reply back. Nothing is
spawned and no socket is opened.

The bridge implements C<initialize> (echoing the protocol version the CLI
offers, and accepting repeated handshakes, which the CLI sends when it
reconnects), C<ping>, C<tools/list> and C<tools/call>. Notifications get no
reply. An unknown method or tool is a C<-32601> error; a bridge failure is
C<-32603>.

=head1 ATTRIBUTES

=head2 server

The L<Claude::Agent::MCP::Server>. Required.

=head2 loop

The L<IO::Async::Loop>, handed to tool handlers and used for the call
timeout.

=head2 tool_timeout

Seconds a tool call may take before it is answered with an error result.
Overrides C<CLAUDE_AGENT_TOOL_TIMEOUT>.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head2 handle

    my $future = $bridge->handle(\%message);

Returns a L<Future> that resolves to the JSON-RPC reply hashref, or to
undef for a notification. A C<tools/call> result is
C<{ content =E<gt> [...], isError =E<gt> true|false }>; a handler result
without a C<content> array of typed blocks becomes an error result. The
C<text> of each block is sent as a string: the CLI rejects a JSON number
there, which a Perl handler returning the result of arithmetic would
otherwise produce.

=head2 timeout_seconds

The tool call timeout in force: C<tool_timeout>, else the environment
variable C<CLAUDE_AGENT_TOOL_TIMEOUT> clamped to 1 to 300, else 60.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
