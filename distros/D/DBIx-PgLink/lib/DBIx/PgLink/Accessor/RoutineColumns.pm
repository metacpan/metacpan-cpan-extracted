package DBIx::PgLink::Accessor::RoutineColumns;

use Moose;
use DBIx::PgLink::Local;
use DBIx::PgLink::Logger;
use Data::Dumper;

our $VERSION = '0.01';

extends 'DBIx::PgLink::Accessor::BaseColumns';

sub get_remote_column_info {
  my $self = shift;

  my $adapter = $self->parent->adapter;

  return $adapter->routine_column_info_arrayref($self->parent->routine_info);

}

__PACKAGE__->meta->make_immutable;

1;
