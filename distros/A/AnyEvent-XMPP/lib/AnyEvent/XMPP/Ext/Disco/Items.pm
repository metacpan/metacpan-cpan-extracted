package AnyEvent::XMPP::Ext::Disco::Items;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use strict;

=head1 NAME

AnyEvent::XMPP::Ext::Disco::Items - Service discovery items

=head1 SYNOPSIS

=head1 DESCRIPTION

This class represents the result of a disco items request
sent by a C<AnyEvent::XMPP::Ext::Disco> handler.

=head1 METHODS

=over 4

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   my $self = bless { @_ }, $class;
   $self->init;
   $self
}

=item B<xml_node ()>

Returns the L<AnyEvent::XMPP::Node> object of the IQ query.

=cut

sub xml_node {
   my ($self) = @_;
   $self->{xmlnode}
}

sub init {
   my ($self) = @_;
   my $node = $self->{xmlnode};
   return unless $node;

   my (@items) = $node->find_all ([qw/disco_items item/]);
   for (@items) {
      push @{$self->{items}}, {
         jid  => $_->attr ('jid'),
         name => $_->attr ('name'),
         node => $_->attr ('node'),
         xml_node => $_,
      };
   }
}

=item B<jid ()>

Returns the JID these items belong to.

=cut

sub jid { $_[0]->{jid} }

=item B<node ()>

Returns the node these items belong to (may be undef).

=cut

sub node { $_[0]->{node} }

=item B<items ()>

Returns a list of hashreferences which contain following keys:

  jid, name, node and xml_node

C<jid> contains the JID of the item.
C<name> contains the name of the item and might be undef.
C<node> contains the node id of the item and might be undef.
C<xml_node> contains the L<AnyEvent::XMPP::Node> object of the item
for further analyses.

=cut

sub items {
   my ($self) = @_;
   @{$self->{items}}
}

=item B<debug_dump ()>

Prints these items to stdout for debugging.

=cut

sub debug_dump {
   my ($self) = @_;
   printf "ITEMS FOR %s (%s):\n", $self->jid, $self->node;
   for ($self->items) {
      printf "   - %-40s (%30s): %s\n", $_->{jid}, $_->{node}, $_->{name}
   }
   print "END ITEMS\n";
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
