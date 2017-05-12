package AnyEvent::XMPP::Error::Parser;
use AnyEvent::XMPP::Error;
use strict;
our @ISA = qw/AnyEvent::XMPP::Error/;

=head1 NAME

AnyEvent::XMPP::Error::Parser - XML parse errors

Subclass of L<AnyEvent::XMPP::Error>

=cut

sub init {
   my ($self) = @_;
}

=head2 METHODS

=over 4

=item B<exception ()>

Returns the XML parser exception.

=cut

sub exception { return $_[0]->{exception} }

=item B<data ()>

Returns the errornous data.

=cut

sub data { $_[0]->{data} }

sub string {
   my ($self) = @_;

   sprintf ("xml parse error: exception: %s, data: [%s]",
      $self->exception,
      $self->data)
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
