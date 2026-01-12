package Claude::Agent::MCP::ToolDefinition;

use 5.020;
use strict;
use warnings;

use Claude::Agent::Logger '$log';
use Scalar::Util qw(blessed);
use Future;
use Types::Common -types;
use Marlin
    'name!'         => Str,
    'description!'  => Str,
    'input_schema!' => HashRef,
    'handler!';                    # Coderef

=head1 NAME

Claude::Agent::MCP::ToolDefinition - MCP tool definition

=head1 DESCRIPTION

Defines a custom MCP tool.

=head2 ATTRIBUTES

=over 4

=item * name - Tool name (will be prefixed with mcp__server__)

=item * description - Description of what the tool does

=item * input_schema - JSON Schema defining the tool's input parameters

=item * handler - Coderef that executes the tool

=back

=head2 HANDLER SIGNATURE

Handlers receive the input arguments and an optional IO::Async::Loop.
They can return either a hashref (synchronous) or a Future (asynchronous).

    # Synchronous handler (backward compatible)
    sub handler {
        my ($args, $loop) = @_;

        # $args is a hashref of input parameters
        # $loop is the IO::Async::Loop (optional, may be undef)

        # Return a result hashref:
        return {
            content => [
                { type => 'text', text => 'Result text' },
            ],
            is_error => 0,  # Optional, default false
        };
    }

    # Asynchronous handler (returns Future)
    sub async_handler {
        my ($args, $loop) = @_;

        # Use loop for async operations
        my $future = $loop->delay_future(after => 1)->then(sub {
            return Future->done({
                content => [{ type => 'text', text => 'Async result' }],
            });
        });

        return $future;  # Return Future that resolves to result hashref
    }

=head2 METHODS

=head3 to_hash

    my $hash = $tool->to_hash();

Convert the tool definition to a hash for JSON serialization.

=cut

sub to_hash {
    my ($self) = @_;
    return {
        name        => $self->name,
        description => $self->description,
        inputSchema => $self->input_schema,
    };
}

=head3 execute

    my $future = $tool->execute(\%args, $loop);

Execute the tool handler with the given arguments. Returns a Future that
resolves to the result hashref.

The handler may return either a hashref (synchronous) or a Future (asynchronous).
Synchronous results are automatically wrapped in C<Future-E<gt>done()>.

=cut

sub execute {
    my ($self, $args, $loop) = @_;

    my $result = eval { $self->handler->($args, $loop) };
    if ($@) {
        # Log full error for debugging but return generic message to avoid leaking sensitive info
        $log->debug(sprintf("Tool execution error: %s", $@));
        return Future->done({
            content  => [{ type => 'text', text => "Error executing tool: " . $self->name }],
            is_error => 1,
        });
    }

    # If handler returned a Future, return it directly
    if (blessed($result) && $result->isa('Future')) {
        # Wrap in error handler to catch async failures
        return $result->else(sub {
            my ($error) = @_;
            $log->debug(sprintf("Async tool execution error: %s", $error));
            return Future->done({
                content  => [{ type => 'text', text => "Error executing tool: " . $self->name }],
                is_error => 1,
            });
        });
    }

    # Synchronous result - wrap in immediate Future
    return Future->done($result);
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
