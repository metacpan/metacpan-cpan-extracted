package AnyEvent::XMPP::Error::IQAuth;
use AnyEvent::XMPP::Error;
use strict;
our @ISA = qw/AnyEvent::XMPP::Error/;

=head1 NAME

AnyEvent::XMPP::Error::IQAuth - IQ authentication error

Subclass of L<AnyEvent::XMPP::Error>

=head2 METHODS

=over 4

=item B<context>

This method returns either:

C<iq_error> which means that a IQ error was caught, which
can be accessed with the C<iq_error> method.

Or: C<no_fields> which means that no form fields were found
in the IQ auth result.

=cut

sub context   { $_[0]->{context} }

sub iq_error { $_[0]->{iq_error} }

sub string {
   my ($self) = @_;

   sprintf "iq auth error: '%s' %s",
      $self->context, ($self->context eq 'iq_error' ? $self->iq_error ()->string : '')
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
