package Data::Transform::SAXBuilder;
use strict;
use warnings;

our $VERSION = '0.05';
use base qw(Data::Transform);

use XML::LibXML;
use XML::SAX::IncrementalBuilder::LibXML;

sub BUFFER  () { 0 }
sub PARSER  () { 1 }
sub HANDLER () { 2 }

=pod

=head1 NAME

Data::Transform::SAXBuilder - A filter for parsing XML with L<XML::LibXML>

=head1 SYSNOPSIS

  use Data::Transform::SAXBuilder;
  my $filter = Data::Transform::SAXBuilder->new();

  my $wheel = POE::Wheel:ReadWrite->new(
 	Filter		=> $filter,
	InputEvent	=> 'input_event',
  );

=head1 DESCRIPTION

L<Data::Transform::SAXBuilder> is used to turn an XML file or stream into
a (series of) DOM tree (fragments). It uses the L<XML::LibXML> modules to do
the parsing and for the building of the DOM tree. This gives you very good
support for most(all?) XML features, and allows you to use a host of extra
modules available for use with L<XML::LibXML>.

To make the potentially time-consuming parsing process not interfere with
event-driven environments (like L<POE>), SAXBuolder will return a series
of document fragments instead of the entire DOM tree.

There are two modes:

=over 2

=item 

The first builds the entire DOM tree, and just gives you pointers into the
tree at various points. This is useful if you know the xml document you are
parsing is not too big, and you want to be able to run XPATH queries on the
entire tree.

=item

The second mode splits up the DOM tree into document fragments and returns
each seperately. You could still build a complete DOM tree from these
fragments. Sometimes that isn't possible, because you're receiving a possibly
endless tree (for example when processing an XMPP stream)

=back

You can control how often you get events by specifying till how deep into
the tree you want to receive notifications. This also controls the size of
the document fragments you'll receive when you're using the second,
'detached' mode.

=head1 PUBLIC METHODS

Data::Transform::SAXBuilder follows the L<Data::Transform> API.
This documentation only covers things that are special to
Data::Transform::SAXBuilder.

=cut

=head2 new

The constructor accepts two arguments which are both optional:

=over 4

=item buffer

A string that is XML waiting to be parsed

=item handler

A SAX Handler that builds your data structures from SAX events. The
default is L<XML::SAX::IncrementalBuilder::LibXML>, which creates DOM tree
fragments. But you could create any sort of object/structure you like.

=back

=cut

sub new {
   my $class = shift;

   my %args = @_;

   my $buffer = $args{buffer} ? [$args{buffer}] : [];
   my $handler = $args{handler};
   if(not defined($handler))
   {
      $handler = XML::SAX::IncrementalBuilder::LibXML->new();
   }

   my $self = [
      $buffer,                                  # BUFFER
      XML::LibXML->new (Handler => $handler),   # PARSER
      $handler,                                 # HANDLER
   ];

   return bless $self, $class;
}

sub clone {
   my $self = shift;

   my $handler = $self->[HANDLER]->clone;
   my $new_self = [
      [],                                       # BUFFER
      XML::LibXML->new (Handler => $handler),   # PARSER
      $handler,                                 # HANDLER
   ];

   return bless $new_self, ref $self;
}

sub get_pending {
   my $self = shift;

   return [ @{$self->[BUFFER]} ] if (@{$self->[BUFFER]} > 0);
   return undef;
}

sub DESTROY {
   my $self = shift;

   delete $self->[BUFFER];
   delete $self->[PARSER];
   delete $self->[HANDLER];
}

=head2 reset_parser

Resets the filter so it is ready to parse a new document from the beginning.

=cut

sub reset_parser {
   my $self = shift;

   $self->[BUFFER] = [];
   $self->[HANDLER]->reset;
   $self->[PARSER] = XML::LibXML->new (Handler => $self->[HANDLER]),
}

sub _handle_get_data {
   my ($self, $newdata) = @_;

   if (defined $newdata) {
      eval {
         $self->[PARSER]->parse_chunk($newdata);
      };
      return Data::Transform::Meta::Error->new($@) if ($@);

      if (defined $self->[HANDLER]->{'EOD'}) {
	 $self->[PARSER]->parse_chunk("", 1);
	 $self->reset_parser;
	 delete $self->[HANDLER]->{'EOD'};
      }
   }

   if($self->[HANDLER]->finished_nodes) {
      my $ret = $self->[HANDLER]->get_node;
      return $ret;
   }
   return;
}

sub _handle_put_data {
   my($self, $node) = @_;

   my $cooked;
   if (ref $node) {
      $cooked = $node->toString;
   } else {
      $cooked = $node;
   }

   return $cooked;
}

1;

__END__

=head1 AUTHOR

Martijn van Beers  <martijn@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006-2008 Martijn van Beers.

Based on L<POE::Filter::XML>, which is Copyright (c) 2003 Nicholas Perez.

Released and distributed under the GPL.

=cut
