package AnyEvent::XMPP::IM::Presence;
use strict;
use AnyEvent::XMPP::Util;
use AnyEvent::XMPP::IM::Message;
use AnyEvent::XMPP::IM::Delayed;

our @ISA = qw/AnyEvent::XMPP::IM::Delayed/;

=head1 NAME

AnyEvent::XMPP::IM::Presence - XMPP presence

=head1 SYNOPSIS

=head1 DESCRIPTION

This module represents an XMPP presence. It stores
the full JID of the contact, the show value, status value
and priority.

L<AnyEvent::XMPP::IM::Presence> is derived from L<AnyEvent::XMPP::IM::Delayed>,
use the interface described there to find out whether this presence was delayed.

=head1 METHODS

=over 4

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   bless { @_ }, $class;
}

sub clone {
   my ($self) = @_;
   my $p = $self->new (connection => $self->{connection});
   $p->{$_} = $self->{$_} for qw/show jid priority status/;
   $p
}

sub update {
   my ($self, $node) = @_;

   $self->fetch_delay_from_node ($node);

   my $type       = $node->attr ('type');
   my ($show)     = $node->find_all ([qw/client show/]);
   my ($priority) = $node->find_all ([qw/client priority/]);

   my %stati;
   $stati{$_->attr ('lang') || ''} = $_->text
      for $node->find_all ([qw/client status/]);

   my $old = $self->clone;

   $self->{show}     = $show     ? $show->text     : undef;
   $self->{priority} = $priority ? $priority->text : undef;
   $self->{status}   = \%stati;
   $self->{type}     = $type;

   $old
}

=item B<jid>

Returns the full JID of this presence.

=cut

sub jid { $_[0]->{jid} }

=item B<priority>

Returns the priority of this presence.

=cut

sub priority { $_[0]->{priority} }

=item B<status_all_lang>

Returns all language tags of available status descriptions.
See also L<status>.

=cut

sub status_all_lang {
   my ($self, $jid) = @_;
   keys %{$self->{status} || []}
}

=item B<show>

Returns the show value of this presence, which is one of:

   'away', 'chat', 'dnd', 'xa'

or the empty string if the presence is 'available'.

=cut

sub show { $_[0]->{show} }

=item B<status ([$lang])>

Returns the presence description. C<$lang> is optional can should be one of
the tags returned by C<status_all_lang>.

=cut

sub status {
   my ($self, $lang) = @_;

   if (defined $lang) {
      return $self->{status}->{$lang}
   } else {
      return $self->{status}->{''}
         if defined $self->{status}->{''};
      return $self->{status}->{en}
         if defined $self->{status}->{en};
   }

   undef
}

=item B<make_message (%args)>

Returns a L<AnyEvent::XMPP::IM::Message> object with the to field set to
this presence full JID.

C<%args> are further arguments to the constructor of the message.

=cut

sub message_class { 'AnyEvent::XMPP::IM::Message' }

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
   printf "   * %-30s [%-5s] (%3d)          {%s}\n",
      $self->jid,
      $self->show     || '',
      $self->priority || 0,
      $self->status   || '',
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
