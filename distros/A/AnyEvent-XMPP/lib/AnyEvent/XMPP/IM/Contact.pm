package AnyEvent::XMPP::IM::Contact;
use strict;
no warnings;
use AnyEvent::XMPP::Util qw/split_jid node_jid/;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use AnyEvent::XMPP::IM::Presence;
use AnyEvent::XMPP::IM::Message;

=head1 NAME

AnyEvent::XMPP::IM::Contact - Instant messaging roster contact

=head1 SYNOPSIS

   my $con = AnyEvent::XMPP::IM::Connection->new (...);
   ...
   my $ro  = $con->roster;
   if (my $c = $ro->get_contact ('test@example.com')) {
      $c->make_message ()->add_body ("Hello there!")->send;
   }

=head1 DESCRIPTION

This module represents a class for contact objects which populate
a roster (L<AnyEvent::XMPP::IM::Roster>.

There are two types of 'contacts' that are managed by this class.
The first are contacts that are on the users roster, and the second
are contacts that are B<not> on the users roster.

To find our whether this is a contact which is actually available
as roster item in the users roster, you should consult the C<is_on_roster>
method (see below). 

Another special kind of contact is the contact which stands for ourself
and is mostly only used for keeping track of our own presences and resources.
But note that even if the C<is_me> method returns true, the C<is_on_roster>
method might also return a true value, in case we have a roster item
of ourself on the roster (which might happen in rare cases :).

You can get an instance of this class only by calling the C<get_contact>
function on a roster object.

=head1 METHODS

=over 4

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   bless { @_ }, $class;
}

=item B<send_update ($cb, %upd)>

This method updates a contact. If the request is finished
it will call C<$cb>. If it resulted in an error the first argument
of that callback will be a L<AnyEvent::XMPP::Error::IQ> object.

The C<%upd> hash should have one of the following keys and defines
what parts of the contact to update:

=over 4

=item name => $name

Updates the name of the contact. C<$name> = '' erases the contact.

=item add_group => $groups

Adds the contact to the groups in the array reference C<$groups>.

=item remove_group => $groups

Removes the contact from the groups in the array reference C<$groups>.

=item groups => $groups

This sets the groups of the contact. C<$groups> should be an array reference
of the groups.

=back

=cut

sub send_update {
   my ($self, $cb, %upd) = @_;

   if ($upd{groups}) {
      $self->{groups} = $upd{groups};
   }
   for my $g (@{$upd{add_group} || []}) {
      push @{$self->{groups}}, $g unless grep { $g eq $_ } $self->groups;
   }
   for my $g (@{$upd{remove_group} || []}) {
      push @{$self->{groups}}, grep { $g ne $_ } $self->groups;
   }

   $self->{connection}->send_iq (
      set => sub {
         my ($w) = @_;
         $w->addPrefix (xmpp_ns ('roster'), '');
         $w->startTag ([xmpp_ns ('roster'), 'query']);
            $w->startTag ([xmpp_ns ('roster'), 'item'], 
               jid => $self->jid,
               (defined $upd{name} ? (name => $upd{name}) : ())
            );
               for ($self->groups) {
                  $w->startTag ([xmpp_ns ('roster'), 'group']);
                  $w->characters ($_);
                  $w->endTag;
               }
            $w->endTag;
         $w->endTag;
      },
      sub {
         my ($node, $error) = @_;
         my $con = undef;
         unless ($error) { $con = $self }
         $cb->($con, $error) if $cb
      }
   );
}

=item B<send_subscribe ()>

This method sends this contact a subscription request.

=cut

sub send_subscribe {
   my ($self) = @_;
   $self->{connection}->send_presence ('subscribe', undef, to => $self->jid);
}

=item B<send_subscribed ()>

This method accepts a contact's subscription request.

=cut

sub send_subscribed {
   my ($self) = @_;
   $self->{connection}->send_presence ('subscribed', undef, to => $self->jid);
}

=item B<send_unsubscribe ()>

This method sends this contact a unsubscription request.

=cut

sub send_unsubscribe {
   my ($self) = @_;
   $self->{connection}->send_presence ('unsubscribe', undef, to => $self->jid);
}

=item B<send_unsubscribed ()>

This method sends this contact a unsubscription request which unsubscribes
ones own presence from him (he wont get any further presence from us).

=cut

sub send_unsubscribed {
   my ($self) = @_;
   $self->{connection}->send_presence ('unsubscribed', undef, to => $self->jid);
}


=item B<update ($item)>

This method wants a L<AnyEvent::XMPP::Node> in C<$item> which
should be a roster item received from the server. The method will
update the contact accordingly and return it self.

=cut

sub update {
   my ($self, $item) = @_;

   my ($jid, $name, $subscription, $ask) =
      (
         $item->attr ('jid'),
         $item->attr ('name'),
         $item->attr ('subscription'),
         $item->attr ('ask')
      );

   $self->{name}         = $name;
   $self->{subscription} = $subscription;
   $self->{groups}       = [ map { $_->text } $item->find_all ([qw/roster group/]) ];
   $self->{ask}          = $ask;

   $self
}

=item B<update_presence ($presence)>

This method updates the presence of contacts on the roster.
C<$presence> must be a L<AnyEvent::XMPP::Node> object and should be
a presence packet.

=cut

sub update_presence {
   my ($self, $node) = @_;

   my $type = $node->attr ('type');
   my $jid  = $node->attr ('from');
   # XXX: should check whether C<$jid> is nice JID.

   $self->touch_presence ($jid);

   my $old;
   my $new;
   if ($type eq 'unavailable') {
      $old = $self->remove_presence ($jid);
   } else {
      $old = $self->touch_presence ($jid)->update ($node);
      $new = $self->touch_presence ($jid);
   }

   ($self, $old, $new)
}

sub remove_presence {
   my ($self, $jid) = @_;
   my $sjid = AnyEvent::XMPP::Util::stringprep_jid ($jid);
   delete $self->{presences}->{$sjid}
}

sub touch_presence {
   my ($self, $jid) = @_;
   my $sjid = AnyEvent::XMPP::Util::stringprep_jid ($jid);

   unless (exists $self->{presences}->{$sjid}) {
      $self->{presences}->{$sjid} =
         AnyEvent::XMPP::IM::Presence->new (connection => $self->{connection}, jid => $jid);
   }
   $self->{presences}->{$sjid}
}

=item B<get_presence ($jid)>

This method returns a presence of this contact if
it is available. The return value is an instance of L<AnyEvent::XMPP::IM::Presence>
or undef if no such presence exists.

=cut

sub get_presence {
   my ($self, $jid) = @_;
   my $sjid = AnyEvent::XMPP::Util::stringprep_jid ($jid);
   $self->{presences}->{$sjid}
}

=item B<get_presences>

Returns all presences of this contact in form of
L<AnyEvent::XMPP::IM::Presence> objects.

=cut

sub get_presences { values %{$_[0]->{presences}} }

=item B<get_priority_presence>

Returns the presence with the highest priority.

=cut

sub get_priority_presence {
   my ($self) = @_;

   my (@pres) =
      sort {
         $self->{presences}->{$b}->priority <=> $self->{presences}->{$a}->priority
      } keys %{$self->{presences}};

   return unless defined $pres[0];
   $self->{presences}->{$pres[0]}
}

=item B<groups>

Returns the list of groups (strings) this contact is in.

=cut

sub groups {
   @{$_[0]->{groups} || []}
}

=item B<jid>

Returns the bare JID of this contact.

=cut

sub jid {
   $_[0]->{jid}
}

=item B<name>

Returns the (nick)name of this contact.

=cut

sub name {
   $_[0]->{name}
}

=item B<is_on_roster ()>

Returns 1 if this is a contact that is officially on the
roster and not just a contact we've received presence information
for.

=cut

sub is_on_roster {
   my ($self) = @_;
   $self->{subscription} && $self->{subscription} ne ''
}

=item B<is_me>

Returns a true value when this contacts stands for ourself
and is only used for receiving presences of our own resources.

=cut

sub is_me {
   my ($self) = @_;
   $self->{is_me}
}

=item B<subscription>

Returns the subscription state of this contact, which
can be one of:

   'none', 'to', 'from', 'both'

If the contact isn't on the roster anymore this method
returns:

   'remove'

=cut

sub subscription {
   $_[0]->{subscription}
}

=item B<ask>

Returns 'subscribe' if we asked this contact for subscription.

=cut

sub ask {
   $_[0]->{ask}
}

=item B<subscription_pending>

Returns true if this contact has a pending subscription.
That means: the contact has to aknowledge the subscription.

=cut

sub subscription_pending {
   my ($self) = @_;
   $self->{ask}
}

=item B<nickname>

Returns the nickname of this contact (or, if none is set in the
roster, it returns the node part of the JID)

=cut

sub nickname {
   my ($self) = @_;
   my $n = $self->name;

   if ($n eq '') {
      $n = node_jid ($self->jid);
   }
   $n
}

sub message_class { 'AnyEvent::XMPP::IM::Message' }

=item B<make_message (%args)>

This method returns a L<AnyEvent::XMPP::IM::Message>
object with the to field set to this contacts JID.

C<%args> are further arguments for the message constructor.

=cut

sub make_message {
   my ($self, %args) = @_;
   $self->message_class ()->new (
      connection => $self->{connection},
      to         => $self->jid,
      %args
   );
}

sub debug_dump {
   my ($self) = @_;
   printf "- %-30s    [%-20s] (%s){%s}\n",
      $self->jid,
      $self->name || '',
      $self->subscription,
      $self->ask;

   for ($self->get_presences) {
      $_->debug_dump;
   }
}

=back

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AnyEvent::XMPP::Contact
