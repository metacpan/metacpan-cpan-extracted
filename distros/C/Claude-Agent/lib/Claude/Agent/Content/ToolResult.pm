package Claude::Agent::Content::ToolResult;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    'type'         => sub { 'tool_result' },
    'tool_use_id!' => Str,              # ID of the corresponding tool_use
    'content!'     => Str | ArrayRef,   # Result content (string or arrayref of blocks)
    'is_error?'    => Bool;             # True if tool execution failed

=head1 NAME

Claude::Agent::Content::ToolResult - Tool result content block

=head1 DESCRIPTION

A tool result content block containing the output from a tool execution.

=head2 ATTRIBUTES

=over 4

=item * type - Always 'tool_result'

=item * tool_use_id - ID of the tool_use block this is responding to

=item * content - Result content (string or ArrayRef of content blocks)

=item * is_error - Boolean indicating if the tool execution failed

=back

=head2 METHODS

=head3 text

    my $text = $block->text;

Helper to get text content from result.

B<Note:> Only extracts text from string content or 'text' type blocks in
array content. Other content types (e.g., 'image') are silently ignored.

=cut

sub text {
    my ($self) = @_;
    my $content = $self->content;

    # If content is a string, return it directly
    return $content unless ref $content;

    # If content is an arrayref, extract text blocks
    my @texts;
    for my $block (@$content) {
        if (ref $block eq 'HASH' && defined $block->{type} && $block->{type} eq 'text' && defined $block->{text}) {
            push @texts, $block->{text};
        }
    }
    return join("\n", @texts);
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
