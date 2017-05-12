package AnyEvent::XMPP::Error::Stanza;
use AnyEvent::XMPP::Error;
use strict;
our @ISA = qw/AnyEvent::XMPP::Error/;

=head1 NAME

AnyEvent::XMPP::Error::Stanza - Stanza errors

Subclass of L<AnyEvent::XMPP::Error>

=cut

sub init {
   my ($self) = @_;
   my $node = $self->xml_node;

   unless (defined $node) {
      $self->{error_cond} = 'client-timeout';
      $self->{error_type} = 'cancel';
      return;
   }

   my @error;
   my ($err) = $node->find_all ([qw/client error/]);

   unless ($err) {
      warn "No error element found in error stanza!";
      $self->{text} = "Unknown Stanza error";
      return
   }

   $self->{error_type} = $err->attr ('type');
   $self->{error_code} = $err->attr ('code');

   if (my ($txt) = $err->find_all ([qw/stanzas text/])) {
      $self->{error_text} = $txt->text;
   }

   for my $er (
     qw/bad-request conflict feature-not-implemented forbidden
        gone internal-server-error item-not-found jid-malformed
        not-acceptable not-allowed not-authorized payment-required
        recipient-unavailable redirect registration-required
        remote-server-not-found remote-server-timeout resource-constraint
        service-unavailable subscription-required undefined-condition
        unexpected-request/)
   {
      if (my ($el) = $err->find_all ([stanzas => $er])) {
         $self->{error_cond}      = $er;
         $self->{error_cond_node} = $el;
         last;
      }
   }

   if (not ($self->{error_cond}) && defined $self->{error_code}) {
      for my $er (keys %AnyEvent::XMPP::Writer::STANZA_ERRORS) {
         my $ern = $AnyEvent::XMPP::Writer::STANZA_ERRORS{$er};
         if ($ern->[1] == $self->{error_code} && $ern->[0] eq $self->{error_type}) {
            $self->{error_cond} = $er;
            last;
         }
      }
   }

   if (!(defined $self->{error_code}) && $self->{error_cond}) {
      my $ern = $AnyEvent::XMPP::Writer::STANZA_ERRORS{$self->{error_cond}};
      $self->{error_type} = $ern->[0];
      $self->{error_code} = $ern->[1];
   }
}

=head2 METHODS

=over 4

=item B<xml_node ()>

Returns the L<AnyEvent::XMPP::Node> object for this Stanza error.
This method returns undef if the Stanza timeouted.

In the case of a timeout the C<condition> method returns C<client-timeout>,
C<type> returns 'cancel' and C<code> undef.

=cut

sub xml_node {
   $_[0]->{node}
}

=item B<type ()>

This method returns one of:

   'cancel', 'continue', 'modify', 'auth' and 'wait'

=cut

sub type { $_[0]->{error_type} }

=item B<code ()>

This method returns the error code if one was found.

=cut

sub code { $_[0]->{error_code} }

=item B<condition ()>

Returns the error condition string if one was found when receiving the Stanza error.
It can be undef or one of:

   bad-request
   conflict
   feature-not-implemented
   forbidden
   gone
   internal-server-error
   item-not-found
   jid-malformed
   not-acceptable
   not-allowed
   not-authorized
   payment-required
   recipient-unavailable
   redirect
   registration-required
   remote-server-not-found
   remote-server-timeout
   resource-constraint
   service-unavailable
   subscription-required
   undefined-condition
   unexpected-request


=cut

sub condition { $_[0]->{error_cond} }

=item B<condition_node ()>

Returns the error condition node if one was found when receiving the Stanza error.
This is mostly for debugging purposes.

=cut

sub condition_node { $_[0]->{error_cond_node} }

=item B<text ()>

The humand readable error portion. Might be undef if none was received.

=cut

sub text { $_[0]->{error_text} }

sub string {
   my ($self) = @_;

   sprintf "stanza error: %s/%s (type %s): %s",
      $self->code || '',
      $self->condition || '',
      $self->type,
      $self->text
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
