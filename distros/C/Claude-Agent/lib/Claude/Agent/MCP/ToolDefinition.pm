package Claude::Agent::MCP::ToolDefinition;

use 5.020;
use strict;
use warnings;

use Claude::Agent::Logger '$log';
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

    sub handler {
        my ($args) = @_;

        # $args is a hashref of input parameters

        # Return a result hashref:
        return {
            content => [
                { type => 'text', text => 'Result text' },
            ],
            is_error => 0,  # Optional, default false
        };
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

    my $result = $tool->execute(\%args);

Execute the tool handler with the given arguments.

=cut

sub execute {
    my ($self, $args) = @_;

    my $result = eval { $self->handler->($args) };
    if ($@) {
        # Log full error for debugging but return generic message to avoid leaking sensitive info
        $log->debug("Tool execution error: %s", $@);
        return {
            content  => [{ type => 'text', text => "Error executing tool: " . $self->name }],
            is_error => 1,
        };
    }

    return $result;
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
