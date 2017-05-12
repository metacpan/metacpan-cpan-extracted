package AnyEvent::XMPP::Component;
use strict;
use AnyEvent::XMPP::Connection;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
our @ISA = qw/AnyEvent::XMPP::Connection/;

=head1 NAME

AnyEvent::XMPP::Component - "XML" stream that implements the XEP-0114

=head1 SYNOPSIS

   use AnyEvent::XMPP::Component;

   my $con = AnyEvent::XMPP::Component->new (
                domain => 'chat.jabber.org'
                host   => 'jabber.org',
                port   => 5347,
                secret => 'insecurepasswordforthehackers'
             );
   $con->reg_cb (session_ready => sub { ... });
   $con->connect;

=head1 DESCRIPTION

This module represents a XMPP connection to a server that authenticates as
component.

This module is a subclass of C<AnyEvent::XMPP::Connection> and inherits all methods.
For example C<reg_cb> and the stanza sending routines.

For additional events that can be registered to look below in the EVENTS section.

Please note that for component several functionality in L<AnyEvent::XMPP::Connection>
might have no effect or not the desired effect. Basically you should
use the L<AnyEvent::XMPP::Component> as component and only handle events
the handle with incoming data. And only use functions that send stanzas.

No effect has the event C<stream_pre_authentication> and the C<authenticate>
method of L<AnyEvent::XMPP::Connection>, because those handle the usual SASL or iq-auth
authentication. "Jabber" components have a completly different authentication
mechanism.

Also note that the support for some XEPs in L<AnyEvent::XMPP::Ext> is just thought
for client side usage, if you miss any functionaly don't hesitate to ask the
author or send him a patch! (See L<AnyEvent::XMPP> for contact information).

=head1 METHODS

=over 4

=item B<new (%args)>

This is the constructor. It takes the same arguments as
the constructor of L<AnyEvent::XMPP::Connection> along with a
few others:

B<NOTE>: Please note that some arguments that L<AnyEvent::XMPP::Connection>
usually takes have no effect when using this class. (That would be
the 'username', 'password', 'resource' and 'jid' arguments for example.)

=over 4

=item secret => $secret

C<$secret> is the secret that will be used for authentication with the server.

=back

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;

   my %args = @_;

   unless (exists $args{initial_presence}) {
      $args{stream_namespace} = 'component';
   }
   
   $args{host} ||= delete $args{server};
   $args{host}
      or die "Required 'host' argument missing to new for this component!";

   unless (defined $args{port}) {
      $args{port} = 5347;
   }

   my $self = $class->SUPER::new (%args);

   $self->{parser}->set_stream_cb (sub {
      my $secret = $self->{parser}->{parser}->xml_escape ($self->{secret});
      my $id = $self->{stream_id} = $_[0]->attr ('id');
      $self->{writer}->send_handshake ($id, $secret);
   });

   $self->reg_cb (recv_stanza_xml => sub {
      my ($self, $node) = @_;
      if ($node->eq (component => 'handshake')) {
         $self->{authenticated} = 1;
         $self->event ('session_ready');
      }
   },
   stream_pre_authentication => sub {
      my ($self, $rcon) = @_;
      $$rcon = 0;
   });

   $self
}

sub default_namespace {
   return 'component';
}

sub authenticate {
   warn "authenticate called! Please read the documentation of "
       ."AnyEvent::XMPP::Component why this is an error!"
}

=back

=head1 EVENTS

These additional events can be registered on with C<reg_cb>:

NOTE: The event C<stream_pre_authentication> should _not_ be handled
and just ignored. Don't attach callbacks to it!

=over 4

=item session_ready

This event indicates that the component has connected successfully
and can now be used to transmit stanzas.

=back

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AnyEvent::XMPP::Component
