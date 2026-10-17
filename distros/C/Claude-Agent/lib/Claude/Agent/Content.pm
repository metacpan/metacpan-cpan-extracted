package Claude::Agent::Content;

use 5.020;
use strict;
use warnings;

use Claude::Agent::Types;
use Claude::Agent::Content::Text;
use Claude::Agent::Content::Thinking;
use Claude::Agent::Content::ToolUse;
use Claude::Agent::Content::ToolResult;

my %CLASS_FOR = (
    text        => 'Claude::Agent::Content::Text',
    thinking    => 'Claude::Agent::Content::Thinking',
    tool_use    => 'Claude::Agent::Content::ToolUse',
    tool_result => 'Claude::Agent::Content::ToolResult',
);

sub from_json {
    my ($class, $data) = @_;

    my $target = $CLASS_FOR{ $data->{type} // '' } or return $data;
    return $target->new(
        Claude::Agent::Types::known_args($target, $data),
        raw => $data,
    );
}

1;

__END__

=head1 NAME

Claude::Agent::Content - Content block types for Claude Agent SDK

=head1 SYNOPSIS

    use Claude::Agent::Content;

    for my $block (@{$msg->content_blocks}) {
        if ($block->isa('Claude::Agent::Content::Text')) {
            print $block->text;
        }
        elsif ($block->isa('Claude::Agent::Content::ToolUse')) {
            print "Tool: ", $block->name, "\n";
        }
    }

=head1 DESCRIPTION

This module loads the content block classes that appear inside assistant
and user messages and provides the factory that builds them from decoded
JSON.

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

Builds the content block object for C<$data-E<gt>{type}>. A block of a type
this module does not know is returned as the hashref it was given. Keys the
class does not declare are not lost: the whole hashref is kept in the
object's C<raw> attribute. A key whose value is JSON null is treated as
absent.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
