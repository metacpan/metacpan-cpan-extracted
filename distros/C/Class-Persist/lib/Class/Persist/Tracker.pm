=head1 NAME

Class::Persist::Tracker - Keep track of all objects

=head1 SYNOPSIS

  $tracker = Class::Persist::Tracker->new();
  $tracker->object( $object );
  $tracker->store();
  print $tracker->class();
  $tracker = Class::Persist::Tracker->load($oid);
  $obj = $tracker->object();

=head1 DESCRIPTION

Store Tracker Tracker keep track of the class and oid of all object,
thus allowing to load an object based on its oid only.

=head1 INHERITANCE

Class::Persist

=head1 METHODS

=cut

package Class::Persist::Tracker;
use strict;
use warnings;
use base  qw( Class::Persist );

__PACKAGE__->db_table('tracker');
__PACKAGE__->db_fields( qw/class/ );
__PACKAGE__->mk_accessors( qw(class) );




=head2 object( $obj )

=cut

sub object {
  my $self = shift;
  my $obj  = shift;
  if (defined $obj) {
    Class::Persist::Error::InvalidParameters->throw(text => "Should be a Class::Persist") unless (ref($obj) and $obj->isa('Class::Persist'));
    $self->set('object', $obj);
    $self->class( ref $obj );
    $self->oid( $obj->oid );
    die if ( $self->oid ne $obj->oid ); # Sanity good.
    return $self;
  }
  elsif ( $self->get('object') ) {
    return $self->get('object');
  }
  else {
    my $class = $self->class or Class::Persist::Error::InvalidParameters->throw(text => "Tracker not loaded");
    $self->loadModule( $class ) or return;
    $self->set( 'object', $class->load( $self->oid ) );
    return $self->get('object');
  }
}


sub validate {
  my $self = shift;
  $self->SUPER::validate(@_) && $self->class;
}


sub track { shift }

##
## DB mapping utilities
##

sub db_fields_spec {
  shift->SUPER::db_fields_spec, (
  'class CHAR(40) NOT NULL',
  )
};



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
