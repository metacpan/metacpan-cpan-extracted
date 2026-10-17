package Claude::Agent::Content::ToolResult;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Claude::Agent::Types;

BEGIN {
    Object::Proto::define('Claude::Agent::Content::ToolResult',
        'type:Str:readonly:default(tool_result)',
        'tool_use_id:Str:required',
        'content:StrOrArrayRef:required',
        'is_error:predicate',
        'raw:HashRef:predicate',
    );
}

sub text {
    my ($self) = @_;
    my $content = $self->content;

    return $content unless ref $content;

    my @texts;
    for my $block (@$content) {
        if (ref $block eq 'HASH' && defined $block->{type} && $block->{type} eq 'text' && defined $block->{text}) {
            push @texts, $block->{text};
        }
    }
    return join("\n", @texts);
}

1;

__END__

=head1 NAME

Claude::Agent::Content::ToolResult - Tool result content block

=head1 DESCRIPTION

A tool result content block containing the output from a tool execution.

=head1 ATTRIBUTES

=head2 type

Always C<tool_result>. Read only.

=head2 tool_use_id

ID of the tool_use block this is responding to.

=head2 content

Result content: a string, or an ArrayRef of content blocks.

=head2 is_error

True when the tool execution failed. Carries whatever the CLI sent (a JSON
boolean decodes to a L<JSON::PP::Boolean>), so test it for truth rather than
comparing it. C<has_is_error> reports whether it was given.

=head2 raw

The decoded block as the CLI sent it, when the object was built by
C<Claude::Agent::Content-E<gt>from_json>.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head2 text

    my $text = $block->text;

The content as text: the string itself, or the C<text> of every text block
joined with newlines.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
