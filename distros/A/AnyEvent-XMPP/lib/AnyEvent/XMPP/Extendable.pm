package AnyEvent::XMPP::Extendable;
no warnings;
use strict;

=head1 NAME

AnyEvent::XMPP::Extendable - Extendable baseclass

=head1 DESCRIPTION

This class provides a mechanism to add extensions.
Please note that the class that derives from this must also
derive from L<AnyEvent::XMPP::Event>!

Please see L<AnyEvent::XMPP::Ext> for more information about this mechanism.

=over 4

=item B<add_extension ($ext)>

This method extends the current object with a L<AnyEvent::XMPP::Ext> object.
C<$ext> must be an instance of L<AnyEvent::XMPP::Ext>.

Basically C<add_extension> makes the extension an event receiver
for all events that the extended object receives.

=cut

sub add_extension {
   my ($self, $ext) = @_;
   $self->add_forward ($ext, sub {
      my ($self, $ext, $ev, @args) = @_;
      return if $ext->{inhibit_forward}->{$ev};
      $ext->_event ($ev, $self, @args);
   });
}

=item B<remove_extension ($ext)>

This method removes the extension C<$ext>.

=cut

sub remove_extension {
   my ($self, $ext) = @_;
   $self->remove_forward ($ext);
}


=back

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AnyEvent::XMPP
