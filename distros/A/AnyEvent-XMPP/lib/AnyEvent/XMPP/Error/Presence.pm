package AnyEvent::XMPP::Error::Presence;
use AnyEvent::XMPP::Error::Stanza;
use strict;
our @ISA = qw/AnyEvent::XMPP::Error::Stanza/;

=head1 NAME

AnyEvent::XMPP::Error::Presence - Presence errors

Subclass of L<AnyEvent::XMPP::Error::Stanza>

=cut

sub string {
   my ($self) = @_;

   sprintf "presence error: %s/%s (type %s): %s",
      $self->code || '',
      $self->condition || '',
      $self->type,
      $self->text
}


=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AnyEvent::XMPP
