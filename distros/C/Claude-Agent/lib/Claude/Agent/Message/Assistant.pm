package Claude::Agent::Message::Assistant;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Scalar::Util qw(blessed);
use Claude::Agent::Content;
use Claude::Agent::Message::Base;

BEGIN {
    Object::Proto::define('Claude::Agent::Message::Assistant',
        extends => 'Claude::Agent::Message::Base',
        'message:HashRef:required',
        'model:predicate',
        'error:predicate',
        '_content_blocks_cache',
    );
}

sub content_blocks {
    my ($self) = @_;

    return [@{$self->_content_blocks_cache}] if $self->_content_blocks_cache;

    my $raw = $self->message->{content};
    $raw = [] unless ref($raw) eq 'ARRAY';

    my @blocks = map {
        ref($_) eq 'HASH'
            ? Claude::Agent::Content->from_json($_)
            : $_
    } @$raw;

    $self->_content_blocks_cache(\@blocks);
    return [@blocks];
}

sub text {
    my ($self) = @_;
    my @texts;
    for my $block (@{$self->content_blocks}) {
        if (blessed($block) && $block->can('type') && $block->type eq 'text' && $block->can('text')) {
            push @texts, $block->text;
        }
        elsif (defined $block && ref($block) eq 'HASH' && defined $block->{type} && $block->{type} eq 'text' && defined $block->{text}) {
            push @texts, $block->{text};
        }
    }
    return join("\n", @texts);
}

sub tool_uses {
    my ($self) = @_;
    return [
        grep {
            (blessed($_) && $_->can('type') && $_->type eq 'tool_use')
            || (ref($_) eq 'HASH' && defined $_->{type} && $_->{type} eq 'tool_use')
        } @{$self->content_blocks}
    ];
}

sub usage {
    my ($self) = @_;
    return $self->message->{usage};
}

sub stop_reason {
    my ($self) = @_;
    return $self->message->{stop_reason};
}

sub message_id {
    my ($self) = @_;
    return $self->message->{id};
}

1;

__END__

=head1 NAME

Claude::Agent::Message::Assistant - Assistant message type

=head1 DESCRIPTION

Represents an assistant (Claude) message in the conversation.

=head1 ATTRIBUTES

=head2 type

Always C<assistant>.

=head2 message

HashRef with C<role>, C<content> (an array of content blocks) and, from
the API, C<id>, C<model>, C<stop_reason> and C<usage>.

=head2 model

The model that generated this response.

=head2 error

Set when the CLI reports an API error for this message.

=head2 uuid, session_id, parent_tool_use_id, agent_id, raw

See L<Claude::Agent::Message::Base>.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head2 content_blocks

    my $blocks = $msg->content_blocks;

Returns an ArrayRef of content block objects (see L<Claude::Agent::Content>).
The objects are built once and shared between calls: mutating one affects
every holder of a reference to it. Copy with L<Storable/dclone> before
modifying a block in place.

=head2 text

    my $text = $msg->text;

The text of every text block, joined with newlines.

=head2 tool_uses

    my $uses = $msg->tool_uses;

ArrayRef of the tool_use blocks.

=head2 usage

The API usage hash for this message, if present.

=head2 stop_reason

The API stop reason for this message, if present.

=head2 message_id

The API message id, if present.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
