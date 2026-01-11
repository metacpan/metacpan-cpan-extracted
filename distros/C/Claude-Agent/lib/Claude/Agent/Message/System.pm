package Claude::Agent::Message::System;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    -base => 'Claude::Agent::Message::Base',
    'subtype!' => Str,       # 'init', 'status', etc.
    'data?'    => HashRef,   # Additional data depending on subtype

    # Fields from init message
    'slash_commands?'      => ArrayRef,
    'claude_code_version?' => Str,
    'tools?'               => ArrayRef,
    'output_style?'        => Str,
    'plugins?'             => ArrayRef,
    'model?'               => Str,
    'mcp_servers?'         => ArrayRef | HashRef,  # JSON format varies by CLI version
    'api_key_source?'      => Str,
    'skills?'              => ArrayRef,
    'permission_mode?'     => Str,
    'cwd?'                 => Str,
    'agents?'              => Any;       # Can be arrayref or hashref

=head1 NAME

Claude::Agent::Message::System - System message type

=head1 DESCRIPTION

Represents a system message from the SDK.

=head2 ATTRIBUTES

=over 4

=item * type - Always 'system'

=item * subtype - The kind of system message ('init', 'status', etc.)

=item * uuid - Unique message identifier

=item * session_id - Session identifier

=item * data - Additional data specific to the subtype

=item * slash_commands - Available slash commands (init)

=item * claude_code_version - Version of Claude Code CLI (init)

=item * tools - Available tools (init)

=item * output_style - Output formatting style (init)

=item * plugins - Loaded plugins (init)

=item * model - Active model name (init)

=item * mcp_servers - MCP server configurations (init)

B<Note:> The JSON format from the CLI may be an ArrayRef or HashRef depending
on the CLI version. This differs from L<Claude::Agent::Options> which uses
HashRef for user-facing configuration.

=item * api_key_source - Source of API key (init)

=item * skills - Available skills (init)

=item * permission_mode - Current permission mode (init)

=item * cwd - Current working directory (init)

=item * agents - Available agent definitions (init)

=back

=head2 SUBTYPES

=over 4

=item * init - Initial message with session configuration

=item * status - Status updates during execution

=item * subagent_start - When a subagent is spawned

=item * subagent_stop - When a subagent finishes

=back

=head2 METHODS

=head3 get_session_id

    my $id = $msg->get_session_id;

Helper for init messages to get session_id from data.

=cut

sub get_session_id {
    my ($self) = @_;
    return $self->session_id // ($self->has_data && $self->data ? $self->data->{session_id} : undef);
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
