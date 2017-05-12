package AnyEvent::XMPP::Ext::MUC::User;
use strict;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use AnyEvent::XMPP::IM::Presence;
use AnyEvent::XMPP::Ext::MUC::Message;
use AnyEvent::XMPP::Util qw/split_jid/;

our @ISA = qw/AnyEvent::XMPP::IM::Presence/;

=head1 NAME

AnyEvent::XMPP::Ext::MUC::User - User class

=head1 SYNOPSIS

=head1 DESCRIPTION

This module represents a user (occupant) handle for a MUC.
This class is derived from L<AnyEvent::XMPP::Presence> as a user has
also a presence within a room.

=head1 METHODS

=over 4

=item B<new (%args)>

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   my $self = $class->SUPER::new (@_);
   $self->init;
   $self
}

sub update {
   my ($self, $node) = @_;
   $self->SUPER::update ($node);
   my ($xuser) = $node->find_all ([qw/muc_user x/]);
   my $from = $node->attr ('from');
   my ($room, $srv, $nick) = split_jid ($from);

   my ($aff, $role, $stati, $jid, $new_nick);
   $self->{stati} ||= {};
   $stati = $self->{stati};

   delete $self->{stati}->{'303'}; # nick change

   if ($xuser) {
      if (my ($item) = $xuser->find_all ([qw/muc_user item/])) {
         $aff      = $item->attr ('affiliation');
         $role     = $item->attr ('role');
         $jid      = $item->attr ('jid');
         $new_nick = $item->attr ('nick');
      }

      for ($xuser->find_all ([qw/muc_user status/])) {
         $stati->{$_->attr ('code')}++;
      }
   }

   $self->{jid}         = $from;
   $self->{nick}        = $nick;
   $self->{affiliation} = $aff;
   $self->{real_jid}    = $jid if defined $jid && $jid ne '';
   $self->{role}        = $role;

   if ($self->is_in_nick_change) {
      $self->{old_nick} = $self->{nick};
      $self->{nick} = $new_nick;
   }
}

sub init {
   my ($self) = @_;
   $self->{connection} = $self->{room}->{muc}->{connection}
}

=item B<nick>

The nickname of the MUC user.

=cut

sub nick { $_[0]->{nick} }

=item B<affiliation>

The affiliation of the user.

=cut

sub affiliation { $_[0]->{affiliation} }

=item B<role>

The role of the user.

=cut

sub role { $_[0]->{role} }

=item B<room>

The L<AnyEvent::XMPP::Ext::MUD::Room> this user is in.

=cut

sub room { $_[0]->{room} }

=item B<in_room_jid>

The room local JID of the user.

=cut

sub in_room_jid { $_[0]->{jid} }

=item B<real_jid>

The real JID of the user, this might be undef if it is an
anonymous room.

=cut

sub real_jid { $_[0]->{real_jid} }

=item B<make_message (%args)>

Returns a L<AnyEvent::XMPP::Ext::MUC::Message> object with the to field set to
this presence full JID.

C<%args> are further arguments to the constructor of the message.

=cut

sub message_class { 'AnyEvent::XMPP::Ext::MUC::Message' }


=item B<did_create_room>

This method returns true if the user created a room.

=cut

sub did_create_room { $_[0]->{stati}->{'201'} }

sub make_message {
   my ($self, %args) = @_;
   $self->message_class ()->new (
      room       => $self->room,
      to         => $self->jid,
      %args
   );
}

sub is_in_nick_change {
   $_[0]->{stati}->{'303'}
}

sub nick_change_old_nick {
   $_[0]->{old_nick}
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
