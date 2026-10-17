package Claude::Agent::Content::ToolUse;

use 5.020;
use strict;
use warnings;

use Object::Proto ();

BEGIN {
    Object::Proto::define('Claude::Agent::Content::ToolUse',
        'type:Str:readonly:default(tool_use)',
        'id:Str:required',
        'name:Str:required',
        'input:HashRef:required',
        'raw:HashRef:predicate',
    );
}

sub is_mcp_tool {
    my ($self) = @_;
    return $self->name =~ /^mcp__/;
}

sub mcp_server {
    my ($self) = @_;
    if ($self->name =~ /^mcp__(.+?)__(.+)$/) {
        return $1;
    }
    return;
}

sub mcp_tool_name {
    my ($self) = @_;
    if ($self->name =~ /^mcp__(.+?)__(.+)$/) {
        return $2;
    }
    return;
}

1;

__END__

=head1 NAME

Claude::Agent::Content::ToolUse - Tool use content block

=head1 DESCRIPTION

A tool use content block representing Claude's request to use a tool.

=head1 ATTRIBUTES

=head2 type

Always C<tool_use>. Read only.

=head2 id

Unique identifier for this tool use.

=head2 name

Name of the tool being used.

=head2 input

HashRef of input parameters for the tool.

=head2 raw

The decoded block as the CLI sent it, when the object was built by
C<Claude::Agent::Content-E<gt>from_json>.

=head1 COMMON TOOL INPUTS

Different tools accept different inputs:

=head2 Read

    { file_path => '/path/to/file', offset => 0, limit => 100 }

=head2 Write

    { file_path => '/path/to/file', content => '...' }

=head2 Edit

    { file_path => '/path/to/file', old_string => '...', new_string => '...' }

=head2 Bash

    { command => '...', description => '...', timeout => 60000 }

=head2 Glob

    { pattern => '**/*.pm', path => '/path/to/search' }

=head2 Grep

    { pattern => 'search term', path => '/path/to/search' }

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head2 is_mcp_tool

    if ($block->is_mcp_tool) { ... }

True when the tool name starts with C<mcp__>.

=head2 mcp_server

    my $server = $block->mcp_server;

The server part of an MCP tool name (C<mcp__server__tool>), or undef.
The split is on the first C<__> after the prefix, so a tool whose own name
contains C<__> keeps it.

=head2 mcp_tool_name

    my $tool = $block->mcp_tool_name;

The tool part of an MCP tool name, or undef.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
