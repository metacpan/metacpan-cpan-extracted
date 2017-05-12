=head1 NAME

Class::Persist::Proxy::Collection - Proxy for objects not loaded yet

=head1 SYNOPSIS

  use qw( Class::Persist::Proxy::Collection );
  my $proxy = Class::Persist::Proxy::Collection->new();
  $proxy->class('Class::Persist::Address');
  $proxy->owner( $contact );
  $proxy->push($object1, $object2);
  $proxy->store();
  $obj1 = $proxy->object_at_index(0);
  
=head1 DESCRIPTION

  Replace several objects in the DB by a Proxy object.
  This allows delayed loading of objects.

=head1 INHERITANCE

  Class::Persist::Proxy EO::Array

=head1 METHODS

=cut

package Class::Persist::Proxy::Collection;
use strict;
use warnings::register;
use base  qw( Class::Persist::Proxy EO::Array );


=head2 element

When called for the first time, create an array of proxies
representing the real objects.

=cut

sub element {
  my $self = shift;
  if (@_) {
    return $self->SUPER::element( @_ );
  }

  $self->load() unless $self->{element};
  $self->SUPER::element;
}


=head2 load()

Replace all the element by proxies

=cut

sub load {
  my $self   = shift;
  my $class  = $self->class   or Class::Persist::Error::InvalidParameters->throw(text => "A class should be defined in proxy");
  $self->loadModule( $class ) or return;
  my $owner = $self->owner    or Class::Persist::Error::InvalidParameters->throw(text => "A owner should be defined in proxy");

  my $ids = $class->oids_for_owner( $owner );
  my @element;
  foreach my $id (@$ids) {
    my $proxy = Class::Persist::Proxy->new();
    $proxy->real_id( $id );
    $proxy->class( $class );
    CORE::push @element, $proxy;
  }
  $self->element(\@element);
}


=head2 store()

Store any non proxy element in the collection and proxy it

=cut

sub store {
  my $self = shift;
  my $owner = $self->owner or Class::Persist::Error::InvalidParameters->throw(text => "A owner should be defined in proxy");
  if (my $element = $self->{element}) {
    foreach my $elem (@$element) {
      next if $elem->isa('Class::Persist::Proxy');
      $elem->owner( $owner );
      $elem->store();
      Class::Persist::Proxy->proxy( $elem );
    }
  }
  $self;
}

sub push {
  my $self = shift;
  my @elements = @_;
  $_->owner($self->owner) for @elements;
  return $self->SUPER::push(@elements);
}

sub unshift {
  my $self = shift;
  my @elements = @_;
  $_->owner($self->owner) for @elements;
  return $self->SUPER::unshift(@elements);
}



=head2 delete( $index )

Without parameter, delete all the elements of the collection.
If an index is given, deletes the related element.

=cut

sub delete {
  my $self  = shift;
  my $index = shift;
  $self->{element} or $self->load() or return;
  if (defined($index)) {
    my $obj = $self->object_at_index($index) or return $self->record('Class::Persist::Error', "Cannot delete, element $index doesn't exist", 1);
    $obj->delete() or return;
    return $self->SUPER::delete($index);
  }
  else {
    if (my $element = $self->element) {
      foreach my $elem (@$element) {
        $elem->delete() or return;
        Class::Persist::Proxy->proxy( $elem );
      }
    }
  }
  1;
}


1;

=head1 SEE ALSO

Class::Persist

=head1 AUTHOR

Fotango

=cut

# Local Variables:
# mode:CPerl
# cperl-indent-level: 2
# indent-tabs-mode: nil
# End:
