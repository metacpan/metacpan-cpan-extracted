package Claude::Agent::MCP::ToolDefinition;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Scalar::Util qw(blessed);
use Future;
use Claude::Agent::Logger '$log';

BEGIN {
    Object::Proto::define('Claude::Agent::MCP::ToolDefinition',
        'name:Str:required',
        'description:Str:required',
        'input_schema:HashRef:required',
        'handler:CodeRef:required',
    );
}

sub to_hash {
    my ($self) = @_;
    return {
        name        => $self->name,
        description => $self->description,
        inputSchema => $self->input_schema,
    };
}

sub execute {
    my ($self, $args, $loop) = @_;

    my $result;
    my $ok = eval { $result = $self->handler->($args, $loop); 1 };
    if (!$ok) {
        $log->debug(sprintf("Tool execution error: %s", $@ // 'unknown'));
        return Future->done($self->_error_result);
    }

    if (blessed($result) && $result->isa('Future')) {
        return $result->else(sub {
            my ($error) = @_;
            $log->debug(sprintf("Async tool execution error: %s", $error // 'unknown'));
            return Future->done($self->_error_result);
        });
    }

    return Future->done($result);
}

sub _error_result {
    my ($self) = @_;
    return {
        content  => [{ type => 'text', text => "Error executing tool: " . $self->name }],
        is_error => 1,
    };
}

1;

__END__

=head1 NAME

Claude::Agent::MCP::ToolDefinition - A tool served from this process

=head1 SYNOPSIS

    my $tool = Claude::Agent::MCP::ToolDefinition->new(
        name         => 'lookup',
        description  => 'Look something up',
        input_schema => { type => 'object', properties => { id => { type => 'string' } } },
        handler      => sub {
            my ($args, $loop) = @_;
            return { content => [{ type => 'text', text => "Found $args->{id}" }] };
        },
    );

The C<tool> function exported by L<Claude::Agent> builds one from positional
arguments.

=head1 DESCRIPTION

Defines a tool Claude can call through an in-process MCP server
(L<Claude::Agent::MCP::Server>). The handler runs in your process with
whatever state it closes over.

=head1 ATTRIBUTES

=head2 name

The tool's name. Claude sees it as C<mcp__E<lt>serverE<gt>__E<lt>nameE<gt>>.

=head2 description

What the tool does, for the model.

=head2 input_schema

JSON Schema for the handler's arguments.

=head2 handler

    sub {
        my ($args, $loop) = @_;
        return {
            content  => [{ type => 'text', text => 'Result text' }],
            is_error => 0,
        };
    }

Receives the arguments and the L<IO::Async::Loop> the query runs on (undef
when there is none). Returns a result hashref, or a L<Future> that
resolves to one. C<content> is an array of content blocks; set
C<is_error> for a tool error. A handler that dies, or whose Future fails,
yields an error result naming the tool; the exception text is logged at
debug level and not sent to the model.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head2 to_hash

    my $hash = $tool->to_hash;

C<{ name, description, inputSchema }>, the MCP C<tools/list> shape.

=head2 execute

    my $future = $tool->execute(\%args, $loop);

Runs the handler and returns a L<Future> of the result hashref.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
