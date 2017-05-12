package AnyEvent::XMPP::IM::Delayed;
use strict;
use AnyEvent::XMPP::Util;
use AnyEvent::XMPP::IM::Message;

=head1 NAME

AnyEvent::XMPP::IM::Delayed - A delayed "XML" stanza

=head1 SYNOPSIS

=head1 DESCRIPTION

This module handles the delayed fields of stanzas and is a superclass of
L<AnyEvent::XMPP::IM::Message> and L<AnyEvent::XMPP::IM::Presence>.

=head1 METHODS

=over 4

=item B<new>

The constructor takes no arguments and makes just a new object of this class.

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   bless { @_ }, $class
}

=item B<xml_node ()>

Returns the L<AnyEvent::XMPP::Node> object for this stream error.

=cut

sub xml_node {
   $_[0]->{node}
}


=item B<fetch_delay_from_node ($node)>

C<$node> must be a L<AnyEvent::XMPP::Node>. This method will try to
fetch the delay information from the C<$node>. It will look in the lists
of child nodes for the delay elements and set it's values from there.

=cut

sub fetch_delay_from_node {
   my ($self, $node) = @_;
   my ($delay)    = $node->find_all ([qw/x_delay x/]);
   my ($newdelay) = $node->find_all ([qw/delay delay/]);

   $delay = $newdelay if $newdelay;

   if ($delay) {
      $self->{delay}->{from}   = $delay->attr ('from');
      $self->{delay}->{stamp}  = $delay->attr ('stamp');
      $self->{delay}->{reason} = $delay->text;
   } else {
      delete $self->{delay}
   }
}

=item B<delay_from>

This method returns either the original source of a maybe delayed
stanza. It's the JID of the original entity that sent the stanza.

This method returns undef if this stanza was not delayed.

And this method returns undef if this stanza had no details about
who sent the message in the first place.

To find out whether this stanza was delayed use the C<delay_stamp>
method.

=cut

sub delay_from {
   my ($self) = @_;
   return unless exists $self->{delay};
   $self->{delay}->{from}
}

=item B<delay_stamp>

This method returns the timestamp in XMPP format which can be fed
to the C<from_xmpp_datetime> function documented in L<AnyEvent::XMPP::Util>.

(Please note that this might be a newstyle XEP-0087 timestamp or
old style legacy timestamp)

If the stanza was not delayed this method returns undef.

=cut

sub delay_stamp {
   my ($self) = @_;
   return unless exists $self->{delay};
   $self->{delay}->{stamp}
}

=item B<delay_reason>

This method might return a human readable string containing the reason
why the stanza was delayed.

Will be undef if stanza contained no delay.

=cut

sub delay_reason {
   my ($self) = @_;
   return unless exists $self->{delay};
   $self->{delay}->{reason}
}

=item B<is_delayed>

If this method returns a true value then this stanza was delayed.
Otherwise it returns undef.

=cut

sub is_delayed {
   my ($self) = @_;
   $self->{delay}
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
