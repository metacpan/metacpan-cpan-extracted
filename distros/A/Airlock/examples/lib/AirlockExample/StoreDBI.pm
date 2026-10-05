package AirlockExample::StoreDBI;

# The four Airlock store subs on plain DBI. Table: examples/schema.sql.
#
#   my $store   = AirlockExample::StoreDBI->new( dbh => $dbh );
#   my $airlock = Airlock->new( store => $store->as_subs, ... );
#
# The handle must have RaiseError set: insert relies on the database refusing
# a duplicate hash or user code.

use Moo;
use Airlock;
use Carp qw( croak );
use namespace::autoclean;

# a DBI handle, or a coderef returning one (for connection pools and forks)
has dbh => ( is => 'ro', required => 1 );

has table => ( is => 'ro', default => 'airlock' );

sub _dbh {
  my ( $self ) = @_;
  return ref $self->dbh eq 'CODE' ? $self->dbh->() : $self->dbh;
}

sub _fields { Airlock->row_fields }

sub insert {
  my ( $self, $row ) = @_;
  my @fields = $self->_fields;
  $self->_dbh->do(
    'INSERT INTO '.$self->table.' ('.join( ', ', @fields ).') VALUES ('.join( ', ', ('?') x @fields ).')',
    undef, @{$row}{@fields}
  );
  return 1;
}

sub find {
  my ( $self, $field, $value ) = @_;
  croak __PACKAGE__.'->find by '.$field.' is not supported' unless $field eq 'hash' || $field eq 'user_code';
  return unless defined $value;
  return $self->_dbh->selectrow_hashref(
    'SELECT '.join( ', ', $self->_fields ).' FROM '.$self->table.' WHERE '.$field.' = ?', undef, $value
  );
}

# The WHERE on the old state is the whole point: of two concurrent redeems
# only one statement changes a row.
sub update {
  my ( $self, $hash, $from_state, $changes ) = @_;
  my %known  = map { $_ => 1 } $self->_fields;
  my @fields = sort keys %$changes;
  croak __PACKAGE__.'->update unknown field' if grep { !$known{$_} } @fields;
  # a reference to a number means "add it", done by the database in one statement
  my @set = map { ref $changes->{$_} eq 'SCALAR' ? $_.' = '.$_.' + ?' : $_.' = ?' } @fields;
  my $changed = $self->_dbh->do(
    'UPDATE '.$self->table.' SET '.join( ', ', @set ).' WHERE hash = ? AND state = ?',
    undef, ( map { ref eq 'SCALAR' ? $$_ : $_ } @{$changes}{@fields} ), $hash, $from_state
  );
  return $changed > 0 ? 1 : 0;
}

sub purge {
  my ( $self, $before ) = @_;
  return $self->_dbh->do( 'DELETE FROM '.$self->table.' WHERE expires < ?', undef, $before ) + 0;
}

sub as_subs {
  my ( $self ) = @_;
  return {
    insert => sub { $self->insert(@_) },
    find   => sub { $self->find(@_) },
    update => sub { $self->update(@_) },
    purge  => sub { $self->purge(@_) }
  };
}

1;
