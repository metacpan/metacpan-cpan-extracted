=head1 NAME

Class::Composite - Implements Composite patterns

=head1 SYNOPSIS

  =========================
  Collection implementation
  =========================

  use Class::Composite;
  my $collection = Class::Composite::Container->new();
  my $element = Class::Composite::Element->new();
  $collection->addElement( $elem );
  $elements = $collection->getElements();


  ========================
  Composite implementation
  ========================

  package graphicBase; # Base for graphics containers and elements
  sub display {
    my $self = shift;
    foreach my $elem (@{$self->getElements()}) {
      $elem->display();
    }
    paint($elem);
  }


  package graphicElement;
  use base qw( Class::Composite::Element graphicBase );


  package graphicContainer;
  use base qw( Class::Composite::Container graphicBase );


  package main;
  use graphicElement;
  use graphicContainer;
  my $element   = graphicElement->new();
  my $container = graphicContainer->new();
  $container->addElement( $element );
  $container->display();

=head1 DESCRIPTION

C<Class::Composite> is used to provide mechanisms used by C<Class::Composite::Container>
and C<Class::Composite::Element>. Class::Composite::* implements a Composite pattern (see OO Patterns books and http://www.uni-paderborn.de/cs/ag-schaefer/Lehre/Lehrveranstaltungen/Vorlesungen/Entwurfsmuster/WS0102/DPSA-IVb.pdf for example).
A composite pattern is a collection implementation which provides same methods to the container and elements.
The reason for using a Composite pattern is to have the same interface to deal with different objects and their containers (collections).

If you only need a collection implementation, then you can inherite from Class::Composite::Container and Class::Composite::Element directly.
If you need specific method that should be applied to both your container and your elements (which is what the Class::Composite is made for),
then you isolate the methods you want to apply on both elements and containers in a specific package.
Then, you inherite from both your package and Class::Composite::Element for elements, and Class::Composite::Container for containers.

=head1 INHERITANCE

Class::Base

=cut
package Class::Composite;

use strict;
use warnings::register;
use Scalar::Util  qw( blessed );

use base  qw( Class::Base );

our $VERSION = 0.2;


=head2 getAll()

Returns an array ref of all elements below, whatever their depth or type.

=cut
sub getAll : method {
  my $self = shift;
  my @elems = ();
  foreach my $junior ( @{$self->getElements()} ) {
    push @elems, $junior;
    push @elems, @{$junior->getAll} if defined($junior);
  }
  \@elems;
}


=head2 getLeaves(start, end)

Returns all Class::Composite::Element contained in the collection, whatever their depth.

=cut
sub getLeaves : method {
  my ($self, $start, $last) = @_;
  my @elements = ();
  foreach my $elem ( @{$self->getElements($start, $last)} ) {
    defined $elem or next;
    if ($elem->isa('Class::Composite::Element')) {
      push @elements, $elem;
    }
    else {
      my $subElems = $elem->getLeaves() || [];
      push @elements, @$subElems if (@$subElems);
    }
  }
  \@elements;
}


=head2 getElements()

Returns the elements just below the current object.
Returns []
must probably be overriden by child classes.

=cut
sub getElements () : method { [] }


=head2 getElement()

Returns undef
must probably be overriden by child classes

=cut
sub getElement () : method { undef }


=head2 nOfElements()

Returns undef, to be overriden by child class

=cut
sub nOfElements { }


=head2 elementType()

Returns the class the element must belongs to, default is
Class::Composite.
Sets it to undef if you don't want any checking to occur.
To be overriden in Child class.

=cut
sub elementType () : method { __PACKAGE__ }


=head2 applyToAll( $sub )

Applies the subroutine $sub to all elements.
The subroutine will receive a collection element as a parameter.

=cut
sub applyToAll : method {
  my ($self, $sub) = @_;
  $sub->( $_ ) foreach ( @{$self->getElements} );
  $self;
}


##
## Helper method
##
sub _warn {
  warn $_[1].' - '.caller(1)." " . caller(2) . "\n";
  undef;
}


1;


__END__

=head1 SEE ALSO

Class::Composite::Container, Class::Composite::Element
http://opensource.fotango.com/ for other goodies

=head1 AUTHOR

"Pierre Denis" <pdenis@fotango.com>

=head1 ACKNOWLEDGEMENTS

Thanks to Leon Brocard and James Duncan for their input and suggestions.

=head1 COPYRIGHT

Copyright (C) 2002, Fotango Ltd. All rights reserved.

This is free software. This software
may be modified and/or distributed under the same terms as Perl
itself.

=cut
