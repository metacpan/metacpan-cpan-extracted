package AnyEvent::XMPP::Ext::MUC::Message;
use strict;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use AnyEvent::XMPP::Util qw/bare_jid res_jid/;
use AnyEvent::XMPP::IM::Message;

our @ISA = qw/AnyEvent::XMPP::IM::Message/;

=head1 NAME

AnyEvent::XMPP::Ext::MUC::Message - A room message

=head1 SYNOPSIS

=head1 DESCRIPTION

This message represents a message from a MUC room. It is
derived from L<AnyEvent::XMPP::IM::Message>. (You can use the
methods from that class to access it for example).

Also the methods like eg. C<make_reply> return a
L<AnyEvent::XMPP::Ext::MUC::Message>.

=head1 METHODS

=over 4

=item B<new (%args)>

This constructor takes the same arguments that the constructor for
L<AnyEvent::XMPP::IM::Message> takes.

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   my $self = $class->SUPER::new (@_);
   $self->{connection} = $self->{room}->{connection};
   $self
}

sub from_node {
   my ($self, $node) = @_;
   $self->SUPER::from_node ($node);
}

=item B<room>

Returns the chatroom in which' context this message
was sent.

=cut

sub room { $_[0]->{room} }

=item B<send ([$room])>

This method send this message. If C<$room>
is defined it will set the connection of this
message object before it is send.

=cut

sub send {
   my ($self, $room) = @_;

   if ($room) {
      $self->{room} = $room;
      $self->{connection} = $self->{room}->{connection};
   }

   my @add;
   push @add, (subject => $self->{subjects})
      if %{$self->{subjects} || {}};
   push @add, (thread => $self->thread)
      if $self->thread;
   push @add, (from => $self->from)
      if defined $self->from;

   $self->{connection}->send_message (
      $self->to, $self->type, $self->{create_cbs},
      body => $self->{bodies},
      @add
   );
}

=item B<make_reply ([$msg])>

This method returns a new instance of L<AnyEvent::XMPP::Ext::MUC::Message>.
The destination address, connection and type of the returned message
object will be set.

If C<$msg> is defined and an instance of L<AnyEvent::XMPP::Ext::MUC::Message>
the destination address, connection and type of C<$msg> will be changed
and this method will not return a new instance of L<AnyEvent::XMPP::Ext::MUC::Message>.

If C<$self> is a message of type 'groupchat' the C<to> attribute
will be set to the bare JID of the room for the reply.

=cut

sub make_reply {
   my ($self, $msg) = @_;

   unless ($msg) {
      $msg = $self->new (room => $self->room);
   }

   $msg->{connection} = $self->{connection};
   $msg->{room}       = $self->{room};

   if ($self->type eq 'groupchat') {
      $msg->to (bare_jid $self->from);

   } else {
      $msg->to ($self->from);
   }
   $msg->type ($self->type);

   $msg
}

=item B<from_nick>

This method returns the nickname of the source
of this message.

=cut

sub from_nick {
   my ($self) = @_;
   res_jid ($self->from)
}

=item B<is_private>

This method returns true when the message was not directed to the
room, but privately to you.

=cut

sub is_private {
   my ($self) = @_;
   $self->type ne 'groupchat'
}

=back

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
