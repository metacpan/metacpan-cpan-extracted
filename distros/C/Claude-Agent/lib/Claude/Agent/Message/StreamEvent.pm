package Claude::Agent::Message::StreamEvent;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Claude::Agent::Message::Base;

BEGIN {
    Object::Proto::define('Claude::Agent::Message::StreamEvent',
        extends => 'Claude::Agent::Message::Base',
        'event:HashRef:required',
    );
}

sub event_type {
    my ($self) = @_;
    return $self->event->{type};
}

sub delta {
    my ($self) = @_;
    return $self->event->{delta};
}

sub text_delta {
    my ($self) = @_;
    my $delta = $self->event->{delta};
    return unless ref $delta eq 'HASH';
    return unless defined $delta->{type} && $delta->{type} eq 'text_delta';
    return $delta->{text};
}

1;

__END__

=head1 NAME

Claude::Agent::Message::StreamEvent - Partial message event

=head1 DESCRIPTION

A raw API streaming event, delivered when the C<include_partial_messages>
option is on. Events cover only the main conversation, so
C<parent_tool_use_id> is always undef.

=head1 ATTRIBUTES

=head2 type

Always C<stream_event>.

=head2 event

The API event hash: C<message_start>, C<content_block_start>,
C<content_block_delta>, C<content_block_stop>, C<message_delta> or
C<message_stop>, with its payload.

=head2 uuid, session_id, parent_tool_use_id, agent_id, raw

See L<Claude::Agent::Message::Base>.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head2 event_type

The event's C<type>.

=head2 delta

The event's C<delta> hash, for C<content_block_delta> and C<message_delta>.

=head2 text_delta

    print $msg->text_delta // '';

The text of a C<text_delta>, or undef for any other event.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
