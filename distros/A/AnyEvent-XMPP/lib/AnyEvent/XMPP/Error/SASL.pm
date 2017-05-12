package AnyEvent::XMPP::Error::SASL;
use AnyEvent::XMPP::Error;
use strict;
our @ISA = qw/AnyEvent::XMPP::Error/;

=head1 NAME

AnyEvent::XMPP::Error::SASL - SASL authentication error

Subclass of L<AnyEvent::XMPP::Error>

=cut

sub init {
   my ($self) = @_;
   my $node = $self->xml_node;

   my $error;
   for ($node->nodes) {
      $error = $_->name;
      last
   }

   $self->{error_cond} = $error;
}

=head2 METHODS

=over 4

=item B<xml_node ()>

Returns the L<AnyEvent::XMPP::Node> object for this stream error.

=cut

sub xml_node {
   $_[0]->{node}
}

=item B<condition ()>

Returns the error condition, which might be one of:

   aborted
   incorrect-encoding
   invalid-authzid
   invalid-mechanism
   mechanism-too-weak
   not-authorized
   temporary-auth-failure

=cut

sub condition {
   $_[0]->{error_cond}
}

sub string {
   my ($self) = @_;

   sprintf "sasl error: %s",
      $self->condition
}

=back

=cut


=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AnyEvent::XMPP
