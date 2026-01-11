package Claude::Agent::Content;

use 5.020;
use strict;
use warnings;

use Types::Common -types;

# Load subclasses
use Claude::Agent::Content::Text;
use Claude::Agent::Content::Thinking;
use Claude::Agent::Content::ToolUse;
use Claude::Agent::Content::ToolResult;

=head1 NAME

Claude::Agent::Content - Content block types for Claude Agent SDK

=head1 SYNOPSIS

    use Claude::Agent::Content;

    # Content blocks are part of assistant messages
    for my $block (@{$msg->content_blocks}) {
        if ($block->isa('Claude::Agent::Content::Text')) {
            print $block->text;
        }
        elsif ($block->isa('Claude::Agent::Content::ToolUse')) {
            print "Tool: ", $block->name, "\n";
        }
    }

=head1 DESCRIPTION

This module contains all content block types that can appear in
assistant messages from the Claude Agent SDK.

=head1 CONTENT TYPES

=over 4

=item * L<Claude::Agent::Content::Text> - Text response content

=item * L<Claude::Agent::Content::Thinking> - Extended thinking content

=item * L<Claude::Agent::Content::ToolUse> - Tool use request

=item * L<Claude::Agent::Content::ToolResult> - Tool execution result

=back

=head1 METHODS

=head2 from_json

    my $block = Claude::Agent::Content->from_json($data);

Factory method to create the appropriate content block type from JSON data.

=cut

sub from_json {
    my ($class, $data) = @_;

    my $type = $data->{type} // '';

    if ($type eq 'text') {
        return Claude::Agent::Content::Text->new(%$data);
    }
    elsif ($type eq 'thinking') {
        return Claude::Agent::Content::Thinking->new(%$data);
    }
    elsif ($type eq 'tool_use') {
        return Claude::Agent::Content::ToolUse->new(%$data);
    }
    elsif ($type eq 'tool_result') {
        return Claude::Agent::Content::ToolResult->new(%$data);
    }
    else {
        # Return as hashref for unknown types
        return $data;
    }
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
