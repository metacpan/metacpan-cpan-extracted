=head1 NAME

Class::Persist::Proxy - Proxy for an object not loaded yet

=head1 SYNOPSIS

  use Class::Persist::Proxy;
  $proxy = Class::Persist::Proxy->new();
  $proxy->class( "AClass" );
  $proxy->owner( $owner );
  $real = $proxy->load();
  
=head1 DESCRIPTION

  Framework to replace objects in the DB by Proxy objects.
  This allows delayed loading of objects.
  A proxy acts as the real object itself, it should be transparent.
  When a method is called on the proxy, the real object is loaded in place of the proxy.
  If owner() is defined, it will autoload the object based on owner id, 
  otherwise it will load the object based on real_id.

=head1 INHERITANCE

  Class::Persist::Base

=head1 METHODS

=head2 class( $class )

=cut

package Class::Persist::Proxy;
use strict;
use warnings;
use Scalar::Util qw( blessed );
use base  qw( Class::Persist::Base );
__PACKAGE__->mk_accessors( qw(real_id) );

our $AUTOLOAD;



=head2 oid( $id )

Tries hard to return the oid of the object proxied,
if it fails, returns the proxy oid.

=cut

sub oid {
  my $self = shift;
  return $self->set($Class::Persist::ID_FIELD, shift) if @_;
  my $id = $self->real_id();
  unless ($id) {
    if ($self->get('owner')) {
      $self->load() or return;
      $id = $self->get($Class::Persist::ID_FIELD);
    }
    else {
      $id = $self->SUPER::oid();
    }
  }
  $id;
}


=head2 class( $class )

Get / set class.
If no class is given, tries to guess using Class::Persist::Tracker

=cut

sub class {
  my $self = shift;
  return $self->set('class', shift) if @_;

  unless ($self->get('class')) {
    require Class::Persist::Tracker;
    my $tracker = Class::Persist::Tracker->load($self->oid)
      or return $self->record('Class::Persist::Error::DB::NotFound', "object " . $self->oid . " not found", 1);
    $self->set('class', $tracker->class);
  }
  return $self->get('class');
}

=head2 owner( $obj )

Get / set owner.
The owner is automatically proxied.

=cut

sub owner {
  my $self = shift;
  if (my ($owner) = @_) {
    blessed($owner) or Class::Persist::Error::InvalidParameters->throw(text => "owner should be an object");
    unless ($owner->isa('Class::Persist::Proxy')) {
      my $proxy = Class::Persist::Proxy->new();
      $proxy->class( ref $owner );
      $proxy->oid( $owner->oid );
      $owner = $proxy;
    }
    return $self->set('owner', $owner);
  }
  return $self->get('owner') || $self->load->owner;
}


=head2 load()

Replace the proxy by its target object

=cut

sub load {
  my $self  = shift;
  my $class = $self->class or return $self->record('Class::Persist::Error::InvalidParameters', "A class should be defined in proxy", 1);
  $self->loadModule( $class ) or return;

  my $obj = $class->load($self->get('owner') || $self->oid);

  unless ($obj) {
    require Class::Persist::Tracker;
    if (my $tracker = Class::Persist::Tracker->load($self->get('owner') || $self->oid)) {
      if (my $object = $tracker->object) {
        $self->_duplicate_from($object);
        bless $self => ref($object);
        return $self;
      }
    }
    return $self->record('Class::Persist::Error::DB::NotFound', "Could not load $class for $self", 1)
  }

  $self->_duplicate_from( $obj );
  bless $self => $class;
}


=head2 proxy( $obj )

Replace object by proxy

=cut

sub proxy {
  my $class  = shift;
  my $obj    = shift;
  my $owner = shift;
  return $obj if $obj->isa(__PACKAGE__);
  $obj->isa('Class::Persist') or Class::Persist::Error::InvalidParameters->throw(text => "object to proxy should be a Class::Persist");
  
  $class->loadModule( ref $obj ) or return;
  my $self = $class->new();
  $self->class( ref $obj );
  if ($owner) {
    $self->owner( $owner );
  }
  $self->real_id( $obj->oid );
  $obj->_duplicate_from( $self );
  bless $obj => $class;
}


sub AUTOLOAD {
  my $self = shift;
  $self = $self->load() or return; # die "Can't find in DB from ".(caller)[0]." line ".(caller)[2];
  my $meth = substr($AUTOLOAD, rindex($AUTOLOAD, ':') + 1);
  my $can = $self->can($meth) or EO::Error::Method::NotFound->throw(text => "Method $meth unknownin class ".ref($self));
  $can->($self, @_);
}

sub DESTROY { 1 }

sub clone {
  my $self = shift;
  $self = $self->load or return;
  return $self->clone(@_);
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
