package My::Storage;
use base 'DBIx::Class::Storage::DBI';

sub last_insert_id {
  my ($self,$source,$col) = @_;
  return $self->dbh_do(sub { $_[1]->last_insert_id(undef,undef,undef,undef); });
}

1;
