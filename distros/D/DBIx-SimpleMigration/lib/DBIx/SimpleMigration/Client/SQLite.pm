package DBIx::SimpleMigration::Client::SQLite;
use parent qw(DBIx::SimpleMigration::Client);

use Carp;

our $VERSION = '1.0.2';

sub _migrations_table_exists {
  my ($self) = @_;

  my $query = "
    SELECT EXISTS (
      SELECT NULL
      FROM sqlite_master
      WHERE type = 'table' AND name = ?
    )
  ";

  my $row = $self->{dbh}->selectrow_hashref($query, {}, $self->{_options}->{migrations_table}) or croak __PACKAGE__ . ': Database error: ' . $self->{dbh}->errstr;

  return $row->{exists};
}

1;
