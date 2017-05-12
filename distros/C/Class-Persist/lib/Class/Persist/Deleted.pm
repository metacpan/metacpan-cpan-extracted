=head1 NAME

Class::Persist::Deleted - Deleted objects

=head1 SYNOPSIS

  $deleted = Class::Persist::Deleted->new();
  $deleted->object( $object );
  $deleted->store();

=head1 DESCRIPTION

Store deleted objects in a serialized form, for debugging purpose

=head1 INHERITANCE

Class::Persist

=head1 METHODS

=cut

package Class::Persist::Deleted;
use strict;
use warnings;
use Storable  qw( nfreeze thaw );
use base  qw( Class::Persist );

__PACKAGE__->db_table('deleted');
__PACKAGE__->db_fields( qw/class dump/ );
__PACKAGE__->binary_fields(qw( dump ));
__PACKAGE__->mk_accessors( qw(object class dump) );



sub load {
  my $class = shift;
  my $self = $class->SUPER::load(@_) or return;
  $self->object( $self->deserialize() );
}


sub deflate {
  my $self   = shift;

  my $object = $self->object or Class::Persist::Error::InvalidParameters->throw(text => "No object set");
  $self->oid( $object->oid ) or return $self->record("No object", 1);
  $self->class( ref $object ) or return $self->record("No object", 1);
  $self->dump( $self->serialize( $object ) );
}


=head2 serialize( $object )

=cut

sub serialize {
  my $self = shift;
  nfreeze( shift ) || Class::Persist::Error::InvalidParameters->throw(text => "Object cannot be serialized");
}


=head2 deserialize( $dump )

=cut

sub deserialize {
  my $self = shift;
  my $dump = shift || $self->dump || Class::Persist::Error::InvalidParameters->throw(text => "No dump to deserialize");
  thaw( $dump );
}


sub validate {
  my $self = shift;
  $self->SUPER::validate(@_) && $self->object;
}

##
## DB mapping utilities
##

sub db_fields_spec {
  my $self = shift;
  my $dbname = $self->dbh()->{Driver}{Name};
  my $blob = $dbname eq 'Pg' ? 'bytea' : 'longblob';

  $self->SUPER::db_fields_spec, (
    'class VARCHAR(255)',
    "dump $blob NOT NULL",
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
