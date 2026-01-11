package Claude::Agent::Content::ToolUse;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    'type'   => sub { 'tool_use' },
    'id!'    => Str,           # Unique tool use ID
    'name!'  => Str,           # Tool name (e.g., 'Read', 'Bash')
    'input!' => HashRef;       # Tool input parameters

=head1 NAME

Claude::Agent::Content::ToolUse - Tool use content block

=head1 DESCRIPTION

A tool use content block representing Claude's request to use a tool.

=head2 ATTRIBUTES

=over 4

=item * type - Always 'tool_use'

=item * id - Unique identifier for this tool use

=item * name - Name of the tool being used

=item * input - HashRef of input parameters for the tool

=back

=head2 COMMON TOOL INPUTS

Different tools accept different inputs:

=head3 Read

    { file_path => '/path/to/file', offset => 0, limit => 100 }

=head3 Write

    { file_path => '/path/to/file', content => '...' }

=head3 Edit

    { file_path => '/path/to/file', old_string => '...', new_string => '...' }

=head3 Bash

    { command => '...', description => '...', timeout => 60000 }

=head3 Glob

    { pattern => '**/*.pm', path => '/path/to/search' }

=head3 Grep

    { pattern => 'search term', path => '/path/to/search' }

=head2 METHODS

=head3 is_mcp_tool

    if ($block->is_mcp_tool) { ... }

Returns true if this is an MCP tool (name starts with 'mcp__').

=head3 mcp_server

    my $server = $block->mcp_server;

Returns the MCP server name if this is an MCP tool.

=head3 mcp_tool_name

    my $tool = $block->mcp_tool_name;

Returns the MCP tool name (without server prefix) if this is an MCP tool.

=cut

sub is_mcp_tool {
    my ($self) = @_;
    return $self->name =~ /^mcp__/;
}

sub mcp_server {
    my ($self) = @_;
    # Split on first occurrence of double underscore after 'mcp__'
    # Example: mcp__my_server__my__tool -> server=my_server, tool=my__tool
    if ($self->name =~ /^mcp__(.+?)__(.+)$/) {
        return $1;
    }
    return;
}

sub mcp_tool_name {
    my ($self) = @_;
    # Split on first occurrence of double underscore after 'mcp__'
    # Example: mcp__my_server__my__tool -> server=my_server, tool=my__tool
    if ($self->name =~ /^mcp__(.+?)__(.+)$/) {
        return $2;
    }
    return;
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
