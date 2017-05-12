package AnyEvent::XMPP::IM::Account;
use strict;
use AnyEvent::XMPP::Util qw/stringprep_jid prep_bare_jid split_jid cmp_jid node_jid/;
use AnyEvent::XMPP::IM::Connection;

use base Object::Event::;

=head1 NAME

AnyEvent::XMPP::IM::Account - Instant messaging account

=head1 SYNOPSIS

   my $cl = AnyEvent::XMPP::IM::Client->new;
   ...
   my $acc = $cl->get_account ($jid);

=head1 DESCRIPTION

This module represents a class for IM accounts. It is used
by L<AnyEvent::XMPP::Client>.

You can get an instance of this class only by calling the C<get_account>
method on a L<AnyEvent::XMPP::Client> object.

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   my $self = bless { @_ }, $class;
   $self
}

sub remove_connection {
   my ($self) = @_;
   delete $self->{con}
}

sub spawn_connection {
   my ($self, %args) = @_;

   $self->{con} = AnyEvent::XMPP::IM::Connection->new (
      jid      => $self->jid,
      password => $self->{password},
      (defined $self->{host} ? (host => $self->{host}) : ()),
      (defined $self->{port} ? (port => $self->{port}) : ()),
      %args,
      %{$self->{args} || {}},
   );

   $self->{con}->reg_cb (
      ext_before_session_ready => sub {
         my ($con) = @_;
         $self->{track} = {};
      },
      ext_before_message => sub {
         my ($con, $msg) = @_;
         my $t = $self->{track};
         my $pfrom = prep_bare_jid $msg->from;

         if (not (exists $t->{$pfrom}) || !cmp_jid ($t->{$pfrom}, $msg->from)) {
            $t->{$pfrom} = $msg->from;
            $self->event (tracked_message_destination => $pfrom, $msg->from);
         }
      }
   );

   $self->{con}
}

=head1 METHODS

=over 4

=item B<connection ()>

Returns the L<AnyEvent::XMPP::IM::Connection> object if this account already
has one (undef otherwise).

=cut

sub connection { $_[0]->{con} }

=item B<is_connected ()>

Returns true if this accunt is connected.

=cut

sub is_connected {
   my ($self) = @_;
   $self->{con} && $self->{con}->is_connected
}

=item B<jid ()>

Returns either the full JID if the account is
connected or returns the bare jid if not.

=cut

sub jid {
   my ($self) = @_;
   if ($self->is_connected) {
      return $self->{con}->jid;
   }
   $_[0]->{jid}
}

=item B<bare_jid ()>

Returns always the bare JID of this account after stringprep has been applied,
so you can compare the JIDs returned from this function.

=cut

sub bare_jid {
   my ($self) = @_;
   prep_bare_jid $self->jid
}

=item B<nickname ()>

Your nickname for this account.

=cut

sub nickname {
   my ($self) = @_;
   # FIXME: fetch real nickname from server somehow? Does that exist?
   # eg. from the roster?
   my ($user, $host, $res) = split_jid ($self->bare_jid);
   $user
}

=item B<nickname_for_jid ($jid)>

This method transforms the C<$jid> to a nickname. It looks the C<$jid>
up in the roster and looks for a nickname. If no nickname could be found
in the roster it returns the node part for the C<$jid>.

=cut

sub nickname_for_jid {
   my ($self, $jid) = @_;

   if ($self->is_connected) {
      my $c = $self->connection->get_roster->get_contact ($jid);
      return $c ? $c->nickname : node_jid ($jid);
   } else {
      return node_jid ($jid);
   }
}

=item B<send_tracked_message ($msg)>

This method sends the L<AnyEvent::XMPP::IM::Message> object in C<$msg>.
The C<to> attribute of the message is adjusted by the conversation tracking
mechanism.

=cut

sub send_tracked_message {
   my ($self, $msg) = @_;

   my $bjid = prep_bare_jid $msg->to;
   $msg->to ($self->{track}->{$bjid} || $bjid);
   $msg->send ($self->connection)
}

=back

=head1 EVENTS

For these events callbacks can be registered (with the L<Object::Event> interface):

=over 4

=item tracked_message_destination => $bare_jid, $full_jid

This event is emitted whenever the message tracking mechanism changes (or sets)
it's destination resource for the C<$bare_jid> to C<$full_jid>.

=item removed

Whenever the account is removed from the L<AnyEvent::XMPP::Client>
(eg. when disconnected) this event is emitted before it is destroyed.

=back

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


1;
