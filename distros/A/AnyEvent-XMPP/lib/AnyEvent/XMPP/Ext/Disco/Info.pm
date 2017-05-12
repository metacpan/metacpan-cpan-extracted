package AnyEvent::XMPP::Ext::Disco::Info;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use strict;

=head1 NAME

AnyEvent::XMPP::Ext::Disco::Info - Service discovery info

=head1 SYNOPSIS

=head1 DESCRIPTION

This class represents the result of a disco info request
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

=item B<jid ()>

Returns the JID these items belong to.

=cut

sub jid { $_[0]->{jid} }

=item B<node ()>

Returns the node these items belong to (may be undef).

=cut

sub node { $_[0]->{node} }

sub init {
   my ($self) = @_;
   my $node = $self->{xmlnode};
   return unless $node;

   my (@ids) = $node->find_all ([qw/disco_info identity/]);
   for (@ids) {
      push @{$self->{identities}}, {
         category => $_->attr ('category'),
         type     => $_->attr ('type'),
         name     => $_->attr ('name'),
         xml_node => $_,
      };
   }

   my (@fs) = $node->find_all ([qw/disco_info feature/]);
   $self->{features}->{$_->attr ('var')} = $_ for @fs;

}

=item B<identities ()>

Returns a list of hashrefs which contain following keys:

   category, type, name, xml_node

C<category> is the category of the identity. C<type> is the 
type of the identity. C<name> is the human readable name of
the identity and might be undef. C<xml_node> is the L<AnyEvent::XMPP::Node>
object of the <identity/> node.

C<category> and C<type> may be one of those defined on:

   http://www.xmpp.org/registrar/disco-categories.html

=cut

sub identities {
   my ($self) = @_;
   @{$self->{identities}}
}

=item B<features ()>

Returns a hashref of key/value pairs where the key is the feature name
as listed on:

   http://www.xmpp.org/registrar/disco-features.html

and the value is a L<AnyEvent::XMPP::Node> object for the <feature/> node.

=cut

sub features { $_[0]->{features} || {} }


=item B<debug_dump ()>

Prints the information of this Info object to stdout.

=cut

sub debug_dump {
   my ($self) = @_;
   printf "INFO FOR %s (%s):\n", $self->jid, $self->node;
   for ($self->identities) {
      printf "   ID     : %20s/%-10s (%s)\n", $_->{category}, $_->{type}, $_->{name}
   }
   for (sort keys %{$self->features}) {
      printf "   FEATURE: %s\n", $_;
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
