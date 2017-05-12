package DBIx::SimpleMigration::Client::Pg;
use parent qw(DBIx::SimpleMigration::Client);

use Carp;

our $VERSION = '1.0.2';

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);

  $self->{options}->{migrations_schema} = 'public' unless $self->{options}->{migrations_schema};
  $self->{options}->{migrations_table} = $self->{options}->{migrations_schema} . '.' . $self->{options}->{migrations_table};

  return $self;
}

sub _create_migrations_schema {
  my ($self) = @_;
  return unless $self->{options}->{migrations_schema};

  my $query = '
    SET client_min_messages = error;
    CREATE SCHEMA IF NOT EXISTS ' . $self->{options}->{migrations_schema};

  eval { $self->{dbh}->do($query) };
  if ($@) {
    croak __PACKAGE__ . ': Error creating schema: ' . $self->{dbh}->errstr;
  }
}

sub _create_migrations_table {
  my ($self) = @_;

  if ($self->{options}->{migrations_schema} ne 'public') {
    $self->_create_migrations_schema;
  }

  my $query = '
    SET client_min_messages = error;
    CREATE TABLE IF NOT EXISTS ' . $self->{options}->{migrations_table} . ' (
      name text primary key not null,
      applied timestamp not null
    )
  ';

  eval { $self->{dbh}->do($query) };
  if ($@) {
    croak __PACKAGE__ . ': Error creating table: ' . $self->{dbh}->errstr;
  }
}

sub _migrations_table_exists {
  my ($self) = @_;

  my $schema_where;
  if ($self->{options}->{migrations_schema}) {
    $schema_where = "AND table_schema = '$self->{options}->{migrations_schema}'";
  }

  my $query = "
    WITH tables AS (
      SELECT table_schema::text || '.' || table_name::text as theTable
      FROM information_schema.tables
    )
    SELECT EXISTS (
      SELECT NULL
      FROM tables
      WHERE theTable = ?
    )
  ";

  my $row = $self->{dbh}->selectrow_hashref($query, {}, $self->{options}->{migrations_table}) or croak __PACKAGE__ . ': Database error: ' . $self->{dbh}->errstr;

  return $row->{exists};
}

sub _lock_migrations_table {
  my ($self) = @_;

  my $query = 'LOCK TABLE ' . $self->{options}->{migrations_table} . ' IN EXCLUSIVE MODE';
  return $self->{dbh}->do($query);
}

1;
