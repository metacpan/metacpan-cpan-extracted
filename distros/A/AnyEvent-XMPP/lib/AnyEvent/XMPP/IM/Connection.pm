package AnyEvent::XMPP::IM::Connection;
use strict;
no warnings;
use AnyEvent::XMPP::Connection;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use AnyEvent::XMPP::IM::Roster;
use AnyEvent::XMPP::IM::Message;
use AnyEvent::XMPP::Util qw/cmp_bare_jid/;
our @ISA = qw/AnyEvent::XMPP::Connection/;

=head1 NAME

AnyEvent::XMPP::IM::Connection - "XML" stream that implements the XMPP RFC 3921.

=head1 SYNOPSIS

   use AnyEvent::XMPP::Connection;

   my $con = AnyEvent::XMPP::Connection->new;

=head1 DESCRIPTION

This module represents a XMPP instant messaging connection and implements
RFC 3921.

This module is a subclass of C<AnyEvent::XMPP::Connection> and inherits all methods.
For example C<reg_cb> and the stanza sending routines.

For additional events that can be registered to look below in the EVENTS section.

=head1 METHODS

=over 4

=item B<new (%args)>

This is the constructor. It takes the same arguments as
the constructor of L<AnyEvent::XMPP::Connection> along with a
few others:

=over 4

=item dont_retrieve_roster => $bool

Set this to a true value if no roster should be requested on connection
establishment. You can retrieve the roster later if you want to
with the C<retrieve_roster> method.

The internal roster will be set even if this option is active, and
even presences will be stored in there, except that the C<get_contacts>
method on the roster object won't return anything as there are
no roster items.

=item initial_presence => $priority

This sets whether the initial presence should be sent. C<$priority>
should be the priority of the initial presence. The default value
for the initial presence C<$priority> is 10.

If you pass a undefined value as C<$priority> no initial presence will
be sent!

=back

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;

   my %args = @_;

   unless (exists $args{initial_presence}) {
      $args{initial_presence} = 10;
   }

   my $self = $class->SUPER::new (%args);

   $self->{roster} = AnyEvent::XMPP::IM::Roster->new (connection => $self);

   $self->reg_cb (message_xml =>
      sub { shift @_; $self->handle_message (@_);  });
   $self->reg_cb (presence_xml =>
      sub { shift @_; $self->handle_presence (@_); });
   $self->reg_cb (iq_set_request_xml =>
      sub { shift @_; $self->handle_iq_set (@_);   });
   $self->reg_cb (disconnect =>
      sub { shift @_; $self->handle_disconnect (@_); });

   $self->reg_cb (stream_ready => sub {
      my ($jid) = @_;
      if ($self->features ()->find_all ([qw/session session/])) {
         $self->send_session_iq;
      } else {
         $self->init_connection;
      }
   });

   my $proxy_cb = sub {
      my ($self, $er) = @_;
      $self->event (error => $er);
   };

   $self->reg_cb (
      session_error  => $proxy_cb,
      roster_error   => $proxy_cb,
      presence_error => $proxy_cb,
      message_error  => $proxy_cb,
   );

   $self
}

sub send_session_iq {
   my ($self) = @_;

   $self->send_iq (set => sub {
      my ($w) = @_;
      $w->addPrefix (xmpp_ns ('session'), '');
      $w->emptyTag ([xmpp_ns ('session'), 'session']);

   }, sub {
      my ($node, $error) = @_;
      if ($node) {
         $self->init_connection;
      } else {
         $self->event (session_error => $error);
      }
   });
}

sub init_connection {
   my ($self) = @_;
   if ($self->{dont_retrieve_roster}) {
      $self->initial_presence;
      $self->{session_active} = 1;
      $self->event ('session_ready');

   } else {
      $self->retrieve_roster (sub {
         $self->initial_presence; # XXX: is this the right order? after roster fetch?
         $self->{session_active} = 1;
         $self->event ('session_ready');
      });
   }
}

sub initial_presence {
   my ($self) = @_;
   if (defined $self->{initial_presence}) {
      $self->send_presence (undef, undef, priority => $self->{initial_presence});
   }
   # else do nothing
}

=item B<retrieve_roster ($cb)>

This method initiates a roster request. If you set C<dont_retrieve_roster>
when creating this connection no roster was retrieved.
You can do that with this method. The coderef in C<$cb> will be
called after the roster was retrieved.

The first argument of the callback in C<$cb> will be the roster
and the second will be a L<AnyEvent::XMPP::Error::IQ> object when
an error occurred while retrieving the roster.

=cut

sub retrieve_roster {
   my ($self, $cb) = @_;

   $self->send_iq (get => sub {
      my ($w) = @_;
      $w->addPrefix (xmpp_ns ('roster'), '');
      $w->emptyTag ([xmpp_ns ('roster'), 'query']);

   }, sub {
      my ($node, $error) = @_;
      if ($node) {
         $self->{roster}->set_retrieved;
         $self->store_roster ($node);
      } else {
         $self->event (roster_error => $error);
      }

      $cb->($self, $self->{roster}, $error) if $cb
   });
}

sub store_roster {
   my ($self, $node) = @_;
   my @upd = $self->{roster}->update ($node);
   $self->event (roster_update => $self->{roster}, \@upd);
}

=item B<get_roster>

Returns the roster object of type L<AnyEvent::XMPP::IM::Roster>.

=cut

sub get_roster {
   my ($self) = @_;
   $self->{roster}
}

sub handle_iq_set {
   my ($self, $node, $handled) = @_;

   if ($node->find_all ([qw/roster query/])) {
      $self->store_roster ($node);
      $self->reply_iq_result ($node);
      $$handled = 1;
   }
}

sub handle_presence {
   my ($self, $node) = @_;
   if (defined ($node->attr ('to')) && !cmp_bare_jid ($node->attr ('to'), $self->jid)) {
      return; # ignore presence that is not for us
   }

   if ($node->attr ('type') eq 'error') {
      my $error = AnyEvent::XMPP::Error::Presence->new (node => $node);
      $self->event (presence_error => $error);
      return if $error->type ne 'continue';
   }

   my ($contact, $old, $new) = $self->{roster}->update_presence ($node);
   $self->event (presence_update => $self->{roster}, $contact, $old, $new)
}

sub handle_message {
   my ($self, $node) = @_;

   if ($node->attr ('type') eq 'error') {
      my $error = AnyEvent::XMPP::Error::Message->new (node => $node);
      $self->event (message_error => $error);
      return if $error->type ne 'continue';
   }

   my $msg = AnyEvent::XMPP::IM::Message->new (connection => $self);
   $msg->from_node ($node);
   $self->event (message => $msg);
}

sub handle_disconnect {
   my ($self) = @_;
   delete $self->{roster};
}

=back

=head1 EVENTS

These additional events can be registered on with C<reg_cb>:

In the following events C<$roster> is the L<AnyEvent::XMPP::IM::Roster>
object you get by calling C<get_roster>.

NODE: The first argument to each callback is always the L<AnyEvent::XMPP::IM::Connection>
object itself. Also see L<Object::Event> for more information about registering
callbacks.

=over 4

=item session_ready

This event is generated when the session has been fully established and
can be used to send around messages and other stuff.

=item session_error => $error

If an error happened during establishment of the session this
event will be generated. C<$error> will be an L<AnyEvent::XMPP::Error::IQ>
error object.

=item roster_update => $roster, $contacts

This event is emitted when a roster update has been received.
C<$contacts> is an array reference of L<AnyEvent::XMPP::IM::Contact> objects
which have changed. If a contact was removed it will return 'remove'
when you call the C<subscription> method on it.

The first time this event is sent is when the roster was received
for the first time.

=item roster_error => $error

If an error happened during retrieval of the roster this event will
be generated.
C<$error> will be an L<AnyEvent::XMPP::Error::IQ> error object.

=item presence_update => $roster, $contact, $old_presence, $new_presence

This event is emitted when the presence of a contact has changed.
C<$contact> is the L<AnyEvent::XMPP::IM::Contact> object which presence status
has changed.
C<$old_presence> is a L<AnyEvent::XMPP::IM::Presence> object which represents the
presence prior to the change.
C<$new_presence> is a L<AnyEvent::XMPP::IM::Presence> object which represents the
presence after to the change. The new presence might be undef if the new presence
is 'unavailable'.

=item presence_error => $error

This event is emitted when a presence stanza error was received.
C<$error> will be an L<AnyEvent::XMPP::Error::Presence> error object.

=item message => $msg

This event is emitted when a message was received.
C<$msg> is a L<AnyEvent::XMPP::IM::Message> object.

=item message_error => $error

This event is emitted when a message stanza error was received.
C<$error> will be an L<AnyEvent::XMPP::Error::Message> error object.

=item contact_request_subscribe => $roster, $contact, $message

This event is generated when the C<$contact> wants to subscribe
to your presence.

If you want to accept or decline the request, call
C<send_subscribed> method of L<AnyEvent::XMPP::IM::Contact> or
C<send_unsubscribed> method of L<AnyEvent::XMPP::IM::Contact> on C<$contact>.

If you want to start a mutual subscription you have to call C<send_subscribe>
B<AFTER> you accepted or declined with C<send_subscribed>/C<send_unsubscribed>.
Calling it in the opposite order gets some servers confused!

If a C<status> element was transmitted with the subscription
it's contents will be in C<$message>. Which is usually a text written
from the one who requests subscription.

=item contact_subscribed => $roster, $contact, $message

This event is generated when C<$contact> subscribed you to his presence successfully.

If a C<status> element was transmitted with the subscribed presence
it's contents will be in C<$message>.

=item contact_did_unsubscribe => $roster, $contact, $message

This event is generated when C<$contact> unsubscribes from your presence.

If you want to unsubscribe from him call the C<send_unsubscribe> method
of L<AnyEvent::XMPP::IM::Contact> on C<$contact>.

If a C<status> element was transmitted with the unsubscription
it's contents will be in C<$message>. Which is usually a text written
from the one who unsubscribes.

=item contact_unsubscribed => $roster, $contact, $message

This event is generated when C<$contact> unsubscribed you from his presence.

If you want to unsubscribe him from your presence call the C<send_unsubscribed>
method of L<AnyEvent::XMPP::IM::Contact> on C<$contact>.

If a C<status> element was transmitted with the unsubscription
it's contents will be in C<$message>.

=back

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AnyEvent::XMPP
