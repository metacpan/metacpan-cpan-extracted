package DBIx::PgLink::Accessor::TableColumns;

use Moose;
use DBIx::PgLink::Local;
use DBIx::PgLink::Logger;
use Data::Dumper;

our $VERSION = '0.01';

extends 'DBIx::PgLink::Accessor::BaseColumns';


has 'pk' => (isa=>'HashRef');


sub get_remote_column_info {
  my $self = shift;

  my $adapter = $self->parent->adapter;

  $self->{pk} = eval {  # primary_key_info() could be not implemented
    my $aref = $adapter->primary_key_info_arrayref(
      $self->parent->remote_catalog,
      $self->parent->remote_schema,
      $self->parent->remote_object,
    ) or return;
    my %pk_cols = map { $_->{'COLUMN_NAME'} => 1 } @{$aref};
    return \%pk_cols;
  };
  trace_msg('INFO', "Primary key could not be detected: $@") 
    if $@ && trace_level >= 1;
  trace_msg('INFO', Data::Dumper->Dump([$self->{pk}], [qw(pk)])) 
    if trace_level >= 3;

  return $adapter->column_info_arrayref(
    $self->parent->remote_catalog,
    $self->parent->remote_schema,
    $self->parent->remote_object,
    '%' # all columns
  );

}


around create_column_metadata => sub {
  my $next = shift;
  my $self = shift;

  my $c = $next->($self, @_);
 
  # table has primary key: search by pk columns only
  if ($self->{pk}) {
    $c->{primary_key} = exists $self->{pk}->{$c->{column_name}} ? 1 : 0;
    $c->{searchable} = $c->{primary_key} ? 1 : 0;
    $c->{nullable} = 0 if $c->{primary_key};
  }

  return $c;
};


__PACKAGE__->meta->make_immutable;

1;
