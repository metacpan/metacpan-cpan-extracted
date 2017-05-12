package AnyEvent::XMPP::Error::MUC;
use AnyEvent::XMPP::Error;
use strict;
our @ISA = qw/AnyEvent::XMPP::Error/;

=head1 NAME

AnyEvent::XMPP::Error::MUC - MUC error

Subclass of L<AnyEvent::XMPP::Error>

=head2 METHODS

=over 4

=cut

sub init {
   my ($self) = @_;
   if ($self->{presence_error}) {
      my %mapping = (
         'not-authorized' => 'password_required',
         'forbidden'      => 'banned',
         'item-not-found' => 'room_locked',
         'not-allowed'    => 'room_not_creatable',
         'not-acceptable' => 'use_reserved_nick',
         'registration-required' => 'not_on_memberlist',
         'conflict'              => 'nickname_in_use',
         'service-unavailable'   => 'room_full',
      );
      my $cond = $self->{presence_error}->{error_cond};
      $self->{type} = $mapping{$cond};
   }
   if ($self->{message_node}) {
      my $error = AnyEvent::XMPP::Error::Message->new (node => $self->{message_node});

      if ($self->{message}->any_subject && not defined $self->{message}->any_body) {
         $self->{type} = 'subject_change_forbidden';
      } else {
         $self->{type} = 'message_error';
      }

      $self->{message_error} = $error;
   }
}

=item B<type>

This method returns either:

=over 4

=item join_timeout

If the joining of the room took too long.

=item no_config_form

If the room we requested the configuration from didn't provide a
data form.

=item subject_change_forbidden

If changing the subject of a room is not allowed.

=item message_error

If this is an unidentified message error.

=back

If we got a presence error the method C<presence_error> returns a
L<AnyEvent::XMPP::Error::Presence> object with further details. However, this class
tries to provide a mapping for you (the developer) to ease the load of figuring
out which error means what. To make identification of the errors with XEP-0045
more clear I included the error codes and condition names.

Here are the more descriptive types:

=over 4

=item password_required

Entering a room Inform user that a password is required.

(Condition: not-authorized, Code: 401)

=item banned

Entering a room Inform user that he or she is banned from the room

(Condition: forbidden, Code: 403)

=item room_locked

Entering a room Inform user that the room does not exist and someone
is currently creating it.

(Condition: item-not-found, Code: 404)

=item room_not_creatable

Entering a room Inform user that room creation is restricted

(Condition: not-allowed, Code: 405)

=item use_reserved_nick

Entering a room Inform user that the reserved roomnick must be used

(Condition: not-acceptable, Code: 406)

=item not_on_memberlist

Entering a room Inform user that he or she is not on the member list

(Condition: registration-required, Code: 407)

=item nickname_in_use

Entering a room Inform user that his or her desired room nickname is in use or registered by another user

(Condition: conflict, Code: 409)

=item room_full

Entering a room Inform user that the maximum number of users has been reached

(Condition: service-unavailable, Code: 503)

=back

The condition and code are also available through the L<AnyEvent::XMPP::Error::Presence>
object returned by C<presence_error>, see below.

=cut

sub type { $_[0]->{type} }

=item B<text>

This method returns a human readable text
if one is available.

=cut

sub text {
   my ($self) = @_;
   if (my $p = $self->presence_error) {
      return $p->text;
   } elsif (my $m = $self->message_error) {
      return $m->text;
   } else {
      return $self->{text}
   }
}

=item B<presence_error>

Returns a L<AnyEvent::XMPP::Error::Presence> object if this error
origins to such an error and not some internal error.

=cut

sub presence_error { $_[0]->{presence_error} }

=item B<message_error>

Returns a L<AnyEvent::XMPP::Error::Message> object if this error
origins to such an error and not some internal error.

=cut

sub message_error { $_[0]->{message_error} }

sub string {
   my ($self) = @_;

   sprintf "muc error: '%s': %s",
      $self->type,
      (
         $self->presence_error
            ? $self->presence_error ()->string
            : $self->text
      )
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
