package DBIx::PgLink::Accessor::HasColumns;

# role for Accessor object

use Moose::Role;
use DBIx::PgLink::Local;
use DBIx::PgLink::Logger;
use DBIx::PgLink::Accessor::BaseColumns;

has 'columns_class' => (is=>'ro', isa=>'Str', required=>1);

has 'columns' => (
  is  => 'rw',
  isa => 'DBIx::PgLink::Accessor::BaseColumns',
  lazy => 1,
  default => sub { 
    my $self = shift;
    return $self->building_mode 
      ? $self->columns_class->new_from_remote_metadata(
          parent => $self,
        )
      : $self->columns_class->load(
          parent    => $self,
          object_id => $self->object_id,
        );
  },
);


after 'save_metadata' => sub {
  my $self = shift;
  $self->columns->save;
};


sub create_rowtype {
  my $self = shift;

  $self->columns->require_quoted_names;

  my @cols = map { "$_->{local_column_quoted} $_->{local_type}" } $self->columns->metadata;

  pg_dbh->do(<<END_OF_SQL);
CREATE TYPE @{[ $self->rowtype_quoted ]} AS (
@{[join ",\n", @cols]}
)
END_OF_SQL
  $self->create_comment(
    type    => "TYPE",
    name    => $self->rowtype_quoted,
    comment => "Row type for remote " . $self->remote_object_type . " ". $self->remote_object_quoted,
  );
  trace_msg('INFO', "Created type " . $self->rowtype_quoted)
    if trace_level >= 2;

}


1;
