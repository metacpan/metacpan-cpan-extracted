package AnyEvent::XMPP::Namespaces;
no warnings;
use strict;
require Exporter;
our @EXPORT_OK = qw/xmpp_ns set_xmpp_ns_alias xmpp_ns_maybe/;
our @ISA = qw/Exporter/;

our %NAMESPACES = (
   client      => 'jabber:client',
   component   => 'jabber:component:accept',
   stream      => 'http://etherx.jabber.org/streams',
   streams     => 'urn:ietf:params:xml:ns:xmpp-streams',
   stanzas     => 'urn:ietf:params:xml:ns:xmpp-stanzas',
   sasl        => 'urn:ietf:params:xml:ns:xmpp-sasl',
   bind        => 'urn:ietf:params:xml:ns:xmpp-bind',
   tls         => 'urn:ietf:params:xml:ns:xmpp-tls',
   roster      => 'jabber:iq:roster',
   register    => 'jabber:iq:register',
   version     => 'jabber:iq:version',
   auth        => 'jabber:iq:auth',
   session     => 'urn:ietf:params:xml:ns:xmpp-session',
   xml         => 'http://www.w3.org/XML/1998/namespace',
   disco_info  => 'http://jabber.org/protocol/disco#info',
   disco_items => 'http://jabber.org/protocol/disco#items',
   register_f  => 'http://jabber.org/features/iq-register',
   iqauth      => 'http://jabber.org/features/iq-auth',
   data_form   => 'jabber:x:data',
   iq_oob      => 'jabber:iq:oob',
   x_oob       => 'jabber:x:oob',
   muc         => 'http://jabber.org/protocol/muc',
   muc_user    => 'http://jabber.org/protocol/muc#user',
   muc_owner   => 'http://jabber.org/protocol/muc#owner',
   search      => 'jabber:iq:search',
   x_delay     => 'jabber:x:delay',
   delay       => 'urn:xmpp:delay',
   ping        => 'urn:xmpp:ping',

   vcard       => 'vcard-temp',
   vcard_upd   => 'vcard-temp:x:update',

   pubsub      => 'http://jabber.org/protocol/pubsub',
   pubsub_own  => 'http://jabber.org/protocol/pubsub#owner',
   pubsub_ev   => 'http://jabber.org/protocol/pubsub#event',
);

=head1 NAME

AnyEvent::XMPP::Namespaces - XMPP namespace collection and aliasing class

=head1 SYNOPSIS

   use AnyEvent::XMPP::Namespaces qw/xmpp_ns set_xmpp_ns_alias/;

   set_xmpp_ns_alias (stanzas => 'urn:ietf:params:xml:ns:xmpp-stanzas');

=head1 DESCRIPTION

This module represents a simple namespaces aliasing mechanism to ease handling
of namespaces when traversing AnyEvent::XMPP::Node objects and writing XML
with AnyEvent::XMPP::Writer.

=head1 XMPP NAMESPACES

There are already some aliases defined for the XMPP XML namespaces
which make handling of namepsaces a bit easier:

   stream  => http://etherx.jabber.org/streams
   xml     => http://www.w3.org/XML/1998/namespace

   streams => urn:ietf:params:xml:ns:xmpp-streams
   session => urn:ietf:params:xml:ns:xmpp-session
   stanzas => urn:ietf:params:xml:ns:xmpp-stanzas
   sasl    => urn:ietf:params:xml:ns:xmpp-sasl
   bind    => urn:ietf:params:xml:ns:xmpp-bind
   tls     => urn:ietf:params:xml:ns:xmpp-tls

   client  => jabber:client
   roster  => jabber:iq:roster
   version => jabber:iq:version
   auth    => jabber:iq:auth

   iq_oob  => jabber:iq:oob
   x_oob   => jabber:x:oob

   disco_info  => http://jabber.org/protocol/disco#info
   disco_items => http://jabber.org/protocol/disco#items

   register    => http://jabber.org/features/iq-register
   iqauth      => http://jabber.org/features/iq-auth
   data_form   => jabber:x:data

   ping        => urn:xmpp:ping

   vcard       => vcard-temp

   pubsub      => http://jabber.org/protocol/pubsub
   pubsub_own  => http://jabber.org/protocol/pubsub#owner
   pubsub_ev   => http://jabber.org/protocol/pubsub#event

=head1 FUNCTIONS

=over 4

=item B<xmpp_ns ($alias)>

Returns am uri for the registered C<$alias> or undef if none exists.

=cut

sub xmpp_ns { return $NAMESPACES{$_[0]} }


=item B<xmpp_ns_maybe ($alias_or_namespace_uri)>

This method tries to find whether there is a alias C<$alias_or_namespace_uri>
registered and if not it returns C<$alias_or_namespace_uri>.

=cut

sub xmpp_ns_maybe {
   my ($alias) = @_;
   return unless defined $alias;
   my $n = xmpp_ns ($alias);
   $n ? $n : $alias
}

=item B<set_xmpp_ns_alias ($alias, $namespace_uri)>

Sets an C<$alias> for the C<$namespace_uri>.

=cut

sub set_xmpp_ns_alias { $NAMESPACES{$_[0]} = $_[1] }

=back

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AnyEvent::XMPP
