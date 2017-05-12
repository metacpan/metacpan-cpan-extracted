=head1 NAME

Class::Composite::Container - Collection of Class::Composite::Element

=head1 SYNOPSIS

  use Class::Composite::Container;
  my $c = Class::Composite::Container->new();
  $c->nextElement();
  $c->resetPointer();
  $c->nextElement();
  $obj = $c->getElement();
  $list = $c->getElements(2, 5);

=head1 DESCRIPTION

I<Class::Composite::Container> acts as a collection of elements.

=head1 INHERITANCE

Class::Composite

=cut
package Class::Composite::Container;

use strict;
use warnings::register;
use Scalar::Util qw ( blessed );

use base  qw( Class::Composite );

our $VERSION = 0.1;


=head1 METHODS

=head2 init( %param )

Parameters are 'elements' and 'elempointer'
init is useful for inheritance, you don't need to redefine new(), but you can redefined init().
See I<Base::Class> documentation.

=cut
sub init : method {
  my $self = shift;
  $self->SUPER::init( @_ );
  $self->{elements}    ||= [];
  $self->{elempointer} ||= 0;
  $self;
}


=head2 elements( ARRAY )

Get/Set elements array

=cut
sub elements : method {
  my $self = shift;
  my $elem = shift or return $self->{elements};
  ref $elem eq 'ARRAY' or return $self->_warn("Not an array ref: $elem");
  $self->{elements} = $elem;
  $self;
}


=head2 elempointer( integer )

Gets or sets the elements pointer. The pointer is garenteed to be between 0 and the number of elements - 1

=cut
sub elempointer : method {
  my ($self, $elem) = @_;
  defined $elem or return $self->{elempointer};
  $elem = $self->nOfElements - 1 if $elem >= $self->nOfElements;
  $elem = 0 if $elem < 0;
  $self->{elempointer} = int $elem;
  $self;
}


=head2 addElement( @elements )

The I<addElement()> method adds elements to the collection.
Returns the collection if ok.

=cut
sub addElement : method {
  my ($self, @args) = @_;

  foreach (@args) {
    $self->_addThis(this => $_) or return;
  }
  $self;
}


=head2 addElementFlat( @elements )

Same than addElement, but flatten everything before adding.
If you add a collection, it will add all elements individually, not the collection.
Returns the collection if ok.

=cut
sub addElementFlat : method {
  my ($self, @args) = @_;
  foreach (@args) {
    $self->_addThis( this => $_,
                     flat => 1   ) or return;
  }
  $self;
}


#
# _addThis(this => $id or $object, flat => 0/1)
#
sub _addThis {
  my ($self, %args) = @_;
  my $object = $args{this};
  my $flat   = $args{flat} || 0;
  $self->checkElement( $object ) or return $self->_warn("Element to add is not of type ".$self->elementType);
  if ($flat and ref($object)) {
    my $objects = $object->isa('Class::Composite::Container') ? $object->getLeaves
                                                              : [ $object ];
    $self->_addTheseObj( $objects );
  }
  else {
    $self->_addTheseObj( [$object] );
  }
}


sub _addTheseObj {
  my ($self, $objects) = @_;
  push @{$self->{elements}}, @$objects;
}


=head2 checkElement( $elem )

Returns true if $elem can be added to the container.
The element must be of the same type than elementType() (see I<Class::Composite>) or is undef.
This method is called for each element added to the collection.

=cut
sub checkElement {
  my ($self, $elem) = @_;
  my $type = $self->elementType or return 1;
  return 1 unless defined $elem;
  if (blessed($elem)) {
    return $elem->isa($type);
  }
  else {
    return ref($elem) eq $type;
  }
}


=head2 getElement( $index )

Returns the element asked. If $index < 0 it backtracks from the last element.
If no index is given, returns the current element.

=cut
sub getElement {
  my ($self, $id) = @_;
  $id = $self->elempointer unless defined $id;

  return unless exists $self->{elements};

  if (defined( $self->{elements}->[$id] )) {
    return $self->{elements}->[$id];
  } else {
    return undef;
  }
}


=head2 getElements( $start, $end )

Returns an array ref of elements.
$start and $end are indexes.
$end is optional - if not given all elements after $start are returned.
If neither $start and $end are given, returns all elements.

=cut
sub getElements {
  my ($self, $start, $end) = @_;
  $start ||= 0;
  return [] unless $self->{elements};
  $end = @{$self->{elements}} - 1 unless defined $end;
  [ @{$self->{elements}}[$start .. $end] ];
}


=head2 removeElement( $index )

If no $index is given, the current element is removed.
Rearrange the collection by shifting to the left the elements > $elem.
Returns the element removed if ok.

=cut
sub removeElement {
  my ($self, $index) = @_;
  $index = $self->elempointer unless defined $index;
  splice @{ $self->{elements} }, $index, 1;
}


=head2 removeAll()

Reset the collection and returns the collection.

=cut
sub removeAll {
  my $self = shift;
  $self->{elements}    = [];
  $self->{elempointer} = 0;
  $self;
}


=head2 nOfElements()

Returns the number of elements

=cut
sub nOfElements {
  scalar(@{$_[0]->{elements}}) || 0;
}


=head2 nextElement()

Returns the current element and increments the internal index.
You can use in a while loop such as:

  while ( my $elem = $container->nextElement ) { ... }

=cut
sub nextElement {
  my $self = shift;
  $self->getElement( $self->incrPointer() );
}


=head2 previousElement()

Decrements the internal index and returns the element

=cut
sub previousElement {
  my $self = shift;
  $self->decrPointer or do { $self->resetPointer(); return };
  $self->getElement();
}


=head2 incrPointer()

Increments the internal index

=cut
sub incrPointer : method {
  $_[0]->{elempointer}++;
}


=head2 decrPointer()

Decrements the internal index

=cut
sub decrPointer : method {
  $_[0]->{elempointer}--;
}


=head2 resetPointer()

Reset pointer to retrieve the first element again
Returns the pointer value before being reset

=cut
sub resetPointer : method {
  my $self = shift;
  my $ret  = $self->{elempointer};
  $self->{elempointer} = shift || 0;
  $ret;
}


=head2 setPointer( $index )

Set pointer to $index. The internal index will be set to 0 if $index < 0 and will be set to the number of elements - 1 if $index >= number of elements
Returns the pointer's former value

=cut
sub setPointer : method {
  my ($self, $i) = @_;
  my $current = $self->{elempointer};
  $i = $self->nOfElements - 1 if ($i >= $self->nOfElements);
  $i = 0                      if ($i < 0);
  $self->{elempointer} = $i;
  $current;
}



1;

__END__

=head1 SEE ALSO

Class::Composite, Class::Composite::Element

=head1 AUTHOR

"Pierre Denis" <pdenis@fotango.com>

=head1 COPYRIGHT

Copyright (C) 2002, Fotango Ltd. All rights reserved.

This is free software. This software
may be modified and/or distributed under the same terms as Perl
itself.

=cut
