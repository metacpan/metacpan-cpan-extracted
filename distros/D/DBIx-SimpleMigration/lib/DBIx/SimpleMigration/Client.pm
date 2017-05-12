package DBIx::SimpleMigration::Client;

use Carp;

our $VERSION = '1.0.2';

sub new {
  my $self = bless {}, shift;
  return unless @_ % 2 == 0;
  my %args = @_;

  $self->{dbh} = $args{dbh};
  $self->{options} = $args{options};

  return $self;
}

sub _create_migrations_table {
  my ($self) = @_;

  my $query = '
    CREATE TABLE IF NOT EXISTS ' . $self->{options}->{migrations_table} . ' (
      name varchar(255) primary key not null,
      applied datetime not null
    )
  ';

  $self->{dbh}->do($query) or croak __PACKAGE__ . ': Error creating table: ' . $self->{dbh}->errstr;

  return $self;
}

sub _migrations_table_exists {
  my ($self) = @_;

  return 0; # checking seems to be largely driver-dependent
}

sub _lock_migrations_table {
  my ($self) = @_;

  return 1; # to be overloaded per-DB
}

sub _applied_migrations {
  my ($self) = @_;

  my $query = '
    SELECT name, applied
    FROM ' . $self->{options}->{migrations_table};

  my $result = $self->{dbh}->selectall_arrayref($query, {Slice => {}});

  my %applied_migrations;
  foreach my $row (@{$result}) {
    $applied_migrations{$row->{name}} = $row->{applied};
  }

  return \%applied_migrations;
}

sub _insert_migration {
  my ($self, $key) = @_;

  eval {
    my $query = 'INSERT INTO ' . $self->{options}->{migrations_table} . ' (name, applied) VALUES (?, CURRENT_TIMESTAMP)';
    my $sth = $self->{dbh}->prepare($query);
    $sth->execute($key);
  };

  if ($@) {
    carp __PACKAGE__ . ': Error recording migration: ' . $self->{dbh}->errstr;
    return;
  }

  return 1;
}

1;

__END__
=encoding utf-8
=head1 NAME

DBIx::SimpleMigration::Client

=head1 DESCRIPTION

This holds the cloned L<DBI> handle and wraps most of the interactions inside some helper methods. This module provides a basic set of functions which should work across most DBI drivers however for specific cases (based on the authors usage), some drivers will instantiate subclasses of this with more specific functionality.

=head1 SYNOPSIS

This module really should only be instatiated by L<DBIx::SimpleMigration>, there's little use in using it directly.

=cut
