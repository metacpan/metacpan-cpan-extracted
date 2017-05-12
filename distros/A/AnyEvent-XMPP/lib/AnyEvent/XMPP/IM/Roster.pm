package AnyEvent::XMPP::IM::Roster;
use AnyEvent::XMPP::IM::Contact;
use AnyEvent::XMPP::IM::Presence;
use AnyEvent::XMPP::Util qw/prep_bare_jid bare_jid cmp_bare_jid/;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use strict;
no warnings;

=head1 NAME

AnyEvent::XMPP::IM::Roster - Instant messaging roster for XMPP

=head1 SYNOPSIS

   my $con = AnyEvent::XMPP::IM::Connection->new (...);
   ...
   my $ro  = $con->roster;
   if (my $c = $ro->get_contact ('test@example.com')) {
      $c->make_message ()->add_body ("Hello there!")->send;
   }

=head1 DESCRIPTION

This module represents a class for roster objects which contain
contact information.

It manages the roster of a JID connected by an L<AnyEvent::XMPP::IM::Connection>.
It manages also the presence information that is received.

You get the roster by calling the C<roster> method on an L<AnyEvent::XMPP::IM::Connection>
object. There is no other way.

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   bless { @_ }, $class;
}

sub update {
   my ($self, $node) = @_;

   my ($query) = $node->find_all ([qw/roster query/]);
   return unless $query;

   my @upd;

   for my $item ($query->find_all ([qw/roster item/])) {
      my $jid = $item->attr ('jid');

      my $sub = $item->attr ('subscription'),
      $self->touch_jid ($jid);

      if ($sub eq 'remove') {
         my $c = $self->remove_contact ($jid);
         $c->update ($item);
      } else {
         push @upd, $self->get_contact ($jid)->update ($item);
      }
   }

   @upd
}

sub update_presence {
   my ($self, $node) = @_;
   my $jid  = $node->attr ('from');
   # XXX: should check whether C<$jid> is nice JID.

   my $type = $node->attr ('type');
   my $contact = $self->touch_jid ($jid);

   my %stati;
   $stati{$_->attr ('lang') || ''} = $_->text
      for $node->find_all ([qw/client status/]);

   if ($type eq 'subscribe') {
      $self->{connection}->event (
         contact_request_subscribe => $self, $contact, $stati{''});

   } elsif ($type eq 'subscribed') {
      $self->{connection}->event (
         contact_subscribed => $self, $contact, $stati{''});

   } elsif ($type eq 'unsubscribe') {
      $self->{connection}->event (
         contact_did_unsubscribe => $self, $contact, $stati{''});

   } elsif ($type eq 'unsubscribed') {
      $self->{connection}->event (
         contact_unsubscribed => $self, $contact, $stati{''});

   } else {
      return $contact->update_presence ($node)
   }
   return ($contact)
}

sub touch_jid {
   my ($self, $jid, $contact) = @_;
   my $bjid = prep_bare_jid ($jid);

   if (cmp_bare_jid ($jid, $self->{connection}->jid)) {
      $self->{myself} =
         $contact
         || AnyEvent::XMPP::IM::Contact->new (
               connection => $self->{connection},
               jid        => AnyEvent::XMPP::Util::bare_jid ($jid),
               is_me      => 1,
            );
      return $self->{myself}
   }

   unless ($self->{contacts}->{$bjid}) {
      $self->{contacts}->{$bjid} =
         $contact
         || AnyEvent::XMPP::IM::Contact->new (
               connection => $self->{connection},
               jid        => AnyEvent::XMPP::Util::bare_jid ($jid),
            )
   }

   $self->{contacts}->{$bjid}
}

sub remove_contact {
   my ($self, $jid) = @_;
   my $bjid = prep_bare_jid ($jid);
   delete $self->{contacts}->{$bjid};
}

sub set_retrieved {
   my ($self) = @_;
   $self->{retrieved} = 1;
}

=head1 METHODS

=over 4

=item B<is_retrieved>

Returns true if this roster was fetched from the server or false if this
roster hasn't been retrieved yet.

=cut

sub is_retrieved {
   my ($self) = @_;
   return $self->{retrieved}
}

=item B<new_contact ($jid, $name, $groups, $cb)>

This method sends a roster item creation request to
the server. C<$jid> is the JID of the contact.
C<$name> is the nickname of the contact, which can be
undef. C<$groups> should be a array reference containing
the groups this contact should be in.

The callback in C<$cb> will be called when the creation is finished. The first
argument will be the C<AnyEvent::XMPP::IM::Contact> object if no error occured. The
second argument will be an L<AnyEvent::XMPP::Error::IQ> object if the request
resulted in an error.

Please note that the contact you are given in that callback might not yet
be on the roster (C<is_on_roster> still returns a false value), if the
server did send the roster push after the iq result of the roster set, so
don't rely on the fact that the contact is on the roster.

=cut

sub new_contact {
   my ($self, $jid, $name, $groups, $cb) = @_;

   $groups = [ $groups ] unless ref $groups;

   my $c = AnyEvent::XMPP::IM::Contact->new (
      connection => $self->{connection},
      jid        => bare_jid ($jid)
   );
   $c->send_update (
       sub {
          my ($con, $err) = @_;
          unless ($err) {
             $self->touch_jid ($jid, $con);
          }
          $cb->($con, $err);
       },
       (defined $name ? (name => $name) : ()),
       groups => ($groups || [])
   );
}

=item B<delete_contact ($jid, $cb)>

This method will send a request to the server to delete this contact
from the roster. It will result in cancelling all subscriptions.

C<$cb> will be called when the request was finished. The first argument
to the callback might be a L<AnyEvent::XMPP::Error::IQ> object if the
request resulted in an error.

=cut

sub delete_contact {
   my ($self, $jid, $cb) = @_;

   $jid = prep_bare_jid $jid;

   $self->{connection}->send_iq (
      set => sub {
         my ($w) = @_;
         $w->addPrefix (xmpp_ns ('roster'), '');
         $w->startTag ([xmpp_ns ('roster'), 'query']);
            $w->emptyTag ([xmpp_ns ('roster'), 'item'], 
               jid => $jid,
               subscription => 'remove'
            );
         $w->endTag;
      },
      sub {
         my ($node, $error) = @_;
         $cb->($error) if $cb
      }
   );
}

=item B<get_contact ($jid)>

Returns the contact on the roster with the JID C<$jid>.
(If C<$jid> is not bare the resource part will be stripped
before searching)

B<NOTE:> This method will also return contacts that we
have only presence for. To be sure the contact is on the
users roster you need to call the C<is_on_roster> method on the
contact.

The return value is an instance of L<AnyEvent::XMPP::IM::Contact>.

=cut

sub get_contact {
   my ($self, $jid) = @_;
   my $bjid = AnyEvent::XMPP::Util::prep_bare_jid ($jid);

   if (cmp_bare_jid ($bjid, $self->{connection}->jid)) {
      return $self->get_own_contact;
   }

   $self->{contacts}->{$bjid}
}

=item B<get_contacts>

Returns the contacts that are on this roster as
L<AnyEvent::XMPP::IM::Contact> objects.

NOTE: This method only returns the contacts that have
a roster item. If you haven't retrieved the roster yet
the presence information is still stored but you have
to get the contacts without a roster item with the
C<get_contacts_off_roster> method. See below.

=cut

sub get_contacts {
   my ($self) = @_;
   grep { $_->is_on_roster } values %{$self->{contacts}}
}

=item B<get_contacts_off_roster>

Returns the contacts that are not on the roster
but for which we have received presence.
Return value is a list of L<AnyEvent::XMPP::IM::Contact> objects.

See also documentation of C<get_contacts> method of L<AnyEvent::XMPP::IM::Roster> above.

=cut

sub get_contacts_off_roster {
   my ($self) = @_;
   grep { not $_->is_on_roster } values %{$self->{contacts}}
}

=item B<get_own_contact>

This method returns a L<AnyEvent::XMPP::IM::Contact> object
which stands for ourself. It will be used to keep track of
our own presences.

=cut

sub get_own_contact {
   my ($self) = @_;
   $self->touch_jid ($self->{connection}->jid);
}

=item B<debug_dump>

This prints the roster and all it's contacts
and their presences.

=cut

sub debug_dump {
   my ($self) = @_;
   print "### ROSTER BEGIN ###\n";
   my %groups;
   for my $contact ($self->get_contacts) {
      push @{$groups{$_}}, $contact for $contact->groups;
      push @{$groups{''}}, $contact unless $contact->groups;
   }

   for my $grp (sort keys %groups) {
      print "=== $grp ====\n";
      $_->debug_dump for @{$groups{$grp}};
   }
   if ($self->get_contacts_off_roster) {
      print "### OFF ROSTER ###\n";
      for my $contact ($self->get_contacts_off_roster) {
         push @{$groups{$_}}, $contact for $contact->groups;
         push @{$groups{''}}, $contact unless $contact->groups;
      }

      for my $grp (sort keys %groups) {
         print "=== $grp ====\n";
         $_->debug_dump for grep { not $_->is_on_roster } @{$groups{$grp}};
      }
   }

   print "### ROSTER END ###\n";
}

=back

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 SEE ALSO

L<AnyEvent::XMPP::IM::Connection>, L<AnyEvent::XMPP::IM::Contact>, L<AnyEvent::XMPP::IM::Presence>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut



1; # End of AnyEvent::XMPP
