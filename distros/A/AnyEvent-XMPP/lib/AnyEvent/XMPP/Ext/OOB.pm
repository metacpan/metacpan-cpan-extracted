package AnyEvent::XMPP::Ext::OOB;
use strict;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use AnyEvent::XMPP::Ext;

our @ISA = qw/AnyEvent::XMPP::Ext/;

=head1 NAME

AnyEvent::XMPP::Ext::OOB - XEP-0066 Out of Band Data

=head1 SYNOPSIS


   my $con = AnyEvent::XMPP::Connection->new (...);
   $con->add_extension (my $disco = AnyEvent::XMPP::Ext::Disco->new);
   $con->add_extension (my $oob = AnyEvent::XMPP::Ext::OOB->new);
   $disco->enable_feature ($oob->disco_feature);

   $oob->reg_cb (oob_recv => sub {
      my ($oob, $con, $node, $url) = @_;

      if (got ($url)) {
         $oob->reply_success ($con, $node);
      } else {
         $oob->reply_failure ($con, $node, 'not-found');
      }
   });

   $oob->send_url (
      $con, 'someonewho@wants.an.url.com', "http://nakedgirls.com/marie_021.jpg",
      "Yaww!!! Hot like SUN!",
      sub {
         my ($error) = @_;
         if ($error) { # then error
         } else { # everything fine
         }
      }
   )


=head1 DESCRIPTION

This module provides a helper abstraction for handling out of band
data as specified in XEP-0066.

The object that is generated handles out of band data requests to and
from others.

There is are also some utility function defined to get for example the
oob info from an XML element:

=head1 FUNCTIONS

=over 4

=item B<url_from_node ($node)>

This function extracts the URL and optionally a description
field from the XML element in C<$node> (which must be a
L<AnyEvent::XMPP::Node>).

C<$node> must be the XML node which contains the <url> and optionally <desc> element
(which is eg. a <x xmlns='jabber:x:oob'> element)!

(This method searches both, the jabber:x:oob and jabber:iq:oob namespaces for
the <url> and <desc> elements).

It returns a hash reference which should have following structure:

   {
      url  => "http://someurl.org/mycoolparty.jpg",
      desc => "That was a party!",
   }

If nothing was found this method returns nothing (undef).

=cut

sub url_from_node {
   my ($node) = @_;
   my ($url)  = $node->find_all ([qw/x_oob url/]);
   my ($desc) = $node->find_all ([qw/x_oob desc/]);
   my ($url2)  = $node->find_all ([qw/iq_oob url/]);
   my ($desc2) = $node->find_all ([qw/iq_oob desc/]);
   $url  ||= $url2;
   $desc ||= $desc2;

   defined $url
      ?  { url => $url->text, desc => ($desc ? $desc->text : undef) }
      : ()
}

=back

=head1 METHODS

=over 4

=item B<new ()>

This is the constructor, it takes no further arguments.

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   my $self = bless { @_ }, $class;
   $self->init;
   $self
}

sub init {
   my ($self) = @_;

   $self->reg_cb (
      iq_set_request_xml => sub {
         my ($self, $con, $node, $handled) = @_;

         for ($node->find_all ([qw/iq_oob query/])) {
            my $url = url_from_node ($_);
            $self->event (oob_recv => $con, $node, $url);
            $$handled = 1;
         }
      }
   );
}

sub disco_feature { (xmpp_ns ('x_oob'), xmpp_ns ('iq_oob')) }

=item B<reply_success ($con, $node)>

This method replies to the sender of the oob that the URL
was retrieved successfully.

C<$con> and C<$node> are the C<$con> and C<$node> arguments
of the C<oob_recv> event you want to reply to.

=cut

sub reply_success {
   my ($self, $con, $node) = @_;
   $con->reply_iq_result ($node);
}

=item B<reply_failure ($con, $node, $type)>

This method replies to the sender that either the transfer was rejected
or it was not fount.

If the transfer was rejectes you have to set C<$type> to 'reject',
otherwise C<$type> must be 'not-found'.

C<$con> and C<$node> are the C<$con> and C<$node> arguments
of the C<oob_recv> event you want to reply to.

=cut

sub reply_failure {
   my ($self, $con, $node, $type) = @_;

   if ($type eq 'reject') {
      $con->reply_iq_error ($node, 'cancel', 'item-not-found');
   } else {
      $con->reply_iq_error ($node, 'modify', 'not-acceptable');
   }
}

=item B<send_url ($con, $jid, $url, $desc, $cb)>

This method sends a out of band file transfer request to C<$jid>.
C<$url> is the URL that the otherone has to download. C<$desc> is an optional
description string (human readable) for the file pointed at by the url and
can be undef when you don't want to transmit any description.

C<$cb> is a callback that will be called once the transfer is successful.

The first argument to the callback will either be undef in case of success
or 'reject' when the other side rejected the file or 'not-found' if the other
side was unable to download the file.

=cut

sub send_url {
   my ($self, $con, $jid, $url, $desc, $cb) = @_;

   $con->send_iq (set => { defns => iq_oob => node => {
      ns => iq_oob => name => 'query', childs => [
         { ns => iq_oob => name => 'url', childs => [ $url ] },
         { ns => iq_oob => name => 'desc', (defined $desc ? (childs => [ $desc ]) : ()) }
      ]
   }}, sub {
      my ($n, $e) = @_;
      if ($e) {
         $cb->($e->condition eq 'item-not-found' ? 'not-found' : 'reject')
            if $cb;
      } else {
         $cb->() if $cb;
      }
   }, to => $jid);
}

=back

=head1 EVENTS

These events can be registered to whith C<reg_cb>:

=over 4

=item oob_recv => $con, $node, $url

This event is generated whenever someone wants to send you a out of band data file.
C<$url> is a hash reference like it's returned by C<url_from_node>.

C<$con> is the L<AnyEvent::XMPP::Connection> (Or L<AnyEvent::XMPP::IM::Connection>)
the data was received from.

C<$node> is the L<AnyEvent::XMPP::Node> of the IQ request, you can get the senders
JID from the 'from' attribute of it.

If you fetched the file successfully you have to call C<reply_success>.
If you want to reject the file or couldn't get it call C<reply_failure>.

=back

=cut

1
