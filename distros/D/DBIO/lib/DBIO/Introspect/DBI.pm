package DBIO::Introspect::DBI;
# ABSTRACT: DBI-based introspection via standard metadata APIs

use strict;
use warnings;
use base qw/DBIO::Introspect::Base/;
use DBI ();
use Scalar::Util 'looks_like_number';
use namespace::clean;



sub dbms_name { $_[0]->{dbms_name} //= $_[0]->dbh->{Driver}->{Name} }


sub table_keys {
  my ($self) = @_;
  my @tables;

  my @types = ('TABLE', 'VIEW');

  my $sth = $self->dbh->table_info(undef, undef, '%', \@types);
  while (my $row = $sth->fetchrow_hashref) {
    my $schema = $row->{TABLE_SCHEM} // '';
    my $name   = $row->{TABLE_NAME} // next;

    # SQLite: only tables in main TEMP etc
    # Oracle: filter out system schemas
    if ($self->dbms_name eq 'Oracle' && $schema =~ /^(SYS|SYSTEM)/) {
      next;
    }

    my $key = $schema ? "${schema}.${name}" : $name;
    push @tables, $key;
  }
  $sth->finish;

  return \@tables;
}


sub table_columns {
  my ($self, $key) = @_;
  my ($schema, $table) = $self->_split_key($key);

  my $sth = $self->dbh->column_info($schema, undef, $table, '%');
  my @cols;
  my %seen;
  while (my $row = $sth->fetchrow_hashref) {
    my $col = $row->{COLUMN_NAME} // next;
    push @cols, $col unless $seen{$col}++;
  }
  $sth->finish;

  # DBI doesn't guarantee order, so query directly for known drivers
  if ($self->dbms_name eq 'SQLite') {
    (my $quoted = $table) =~ s/'/''/g;
    my $info = $self->dbh->prepare("PRAGMA table_info('$quoted')");
    $info->execute;
    @cols = ();
    %seen = ();
    while (my $row = $info->fetch) {
      push @cols, $row->[1] unless $seen{$row->[1]}++;
    }
  }

  return \@cols;
}


sub table_columns_info {
  my ($self, $key) = @_;
  my ($schema, $table) = $self->_split_key($key);

  my %cols;
  my $sth = $self->dbh->column_info($schema, undef, $table, '%');
  while (my $row = $sth->fetchrow_hashref) {
    my $col = $row->{COLUMN_NAME} // next;

    my $dt = $row->{DATA_TYPE};
    my $type_str = $row->{TYPE_NAME} // '';
    my $size = $row->{COLUMN_SIZE};

    # MySQL reports TEXT as varchar(65535)
    if ($type_str =~ /varchar/i && defined $size && $size == 65535) {
      $type_str = 'text';
    }

    my $default = $row->{COLUMN_DEF};
    # Strip quotes from default values
    if (defined $default && $default =~ /^'(.*)'$/) {
      $default = $1;
    }

    my $auto_increment =
         ($row->{COLUMN_DEF} // '') =~ /nextval/i  # PostgreSQL serial
      || $row->{mysql_is_auto_increment}            # DBD::mysql / DBD::MariaDB
      ? 1 : 0;

    $cols{$col} = {
      data_type        => $dt // 'varchar',
      type             => $type_str,
      size             => looks_like_number($size) ? $size : undef,
      is_nullable      => (($row->{NULLABLE} // 1) == 1 ? 1 : 0),
      default_value    => $default,
      is_auto_increment => $auto_increment,
    };
  }
  $sth->finish;

  return \%cols;
}


sub table_pk_info {
  my ($self, $key) = @_;
  my ($schema, $table) = $self->_split_key($key);

  my $sth = $self->dbh->primary_key_info($schema, undef, $table)
    or return [];
  my @rows;
  while (my $row = $sth->fetchrow_hashref) {
    push @rows, $row if defined $row->{COLUMN_NAME};
  }
  $sth->finish;

  # Composite keys: order by KEY_SEQ
  my @pk = map { $_->{COLUMN_NAME} }
           sort { ($a->{KEY_SEQ} // 0) <=> ($b->{KEY_SEQ} // 0) } @rows;

  return \@pk;
}


sub table_uniq_info {
  my ($self, $key) = @_;
  my ($schema, $table) = $self->_split_key($key);

  # Not all DBD drivers implement statistics_info
  my $sth = eval { $self->dbh->statistics_info(undef, $schema, $table, 1, 1) }
    or return [];

  # Group index rows: each row is one column of one index
  my (%idx_cols, @idx_order);
  while (my $row = $sth->fetchrow_hashref) {
    my $idx_name = $row->{INDEX_NAME} // next;
    my $col      = $row->{COLUMN_NAME} // next;
    next if $row->{NON_UNIQUE};

    push @idx_order, $idx_name unless $idx_cols{$idx_name};
    push @{ $idx_cols{$idx_name} }, [ $row->{ORDINAL_POSITION} // 0, $col ];
  }
  $sth->finish;

  my @uniq;
  for my $idx_name (@idx_order) {
    my @cols = map { $_->[1] } sort { $a->[0] <=> $b->[0] } @{ $idx_cols{$idx_name} };
    push @uniq, [ $idx_name, \@cols ];
  }

  return \@uniq;
}


sub table_fk_info {
  my ($self, $key) = @_;
  my ($schema, $table) = $self->_split_key($key);

  # Drivers without FK support return undef
  my $sth = $self->dbh->foreign_key_info(undef, undef, undef, undef, $schema, $table)
    or return [];

  # One row per FK column; group composite FKs by constraint name.
  # DBI allows two naming styles: SQL/CLI (UK_/FK_) and ODBC (PK/FK).
  my (%fk, @fk_order);
  while (my $row = $sth->fetchrow_hashref) {
    my $local_col  = $row->{FK_COLUMN_NAME} // $row->{FKCOLUMN_NAME} // next;
    my $remote_tab = $row->{UK_TABLE_NAME}  // $row->{PKTABLE_NAME} // next;
    my $fk_name    = $row->{FK_NAME} // $remote_tab;
    my $seq        = $row->{ORDINAL_POSITION} // $row->{KEY_SEQ} // 0;

    push @fk_order, $fk_name unless $fk{$fk_name};
    my $fk = $fk{$fk_name} //= {
      remote_table  => $remote_tab,
      remote_schema => $row->{UK_TABLE_SCHEM} // $row->{PKTABLE_SCHEM},
      cols          => [],
    };
    push @{ $fk->{cols} },
      [ $seq, $local_col, $row->{UK_COLUMN_NAME} // $row->{PKCOLUMN_NAME} ];
  }
  $sth->finish;

  my @fks;
  for my $fk_name (@fk_order) {
    my $fk = $fk{$fk_name};
    my @cols = sort { $a->[0] <=> $b->[0] } @{ $fk->{cols} };
    push @fks, {
      local_columns  => [ map { $_->[1] } @cols ],
      remote_table   => $fk->{remote_table},
      remote_schema  => $fk->{remote_schema},
      remote_columns => [ grep { defined } map { $_->[2] } @cols ],
      attrs          => {},
    };
  }

  return \@fks;
}


sub table_is_view {
  my ($self, $key) = @_;
  my ($schema, $table) = $self->_split_key($key);

  my $sth = $self->dbh->table_info($schema, undef, $table, ['VIEW']);
  my $row = $sth->fetchrow_hashref;
  $sth->finish;

  return $row ? 1 : 0;
}


sub view_definition {
  my ($self, $key) = @_;
  my ($schema, $table) = $self->_split_key($key);

  # Most DBI drivers don't support this, but SQLite does
  if ($self->dbms_name eq 'SQLite') {
    my $sth = $self->dbh->prepare("SELECT sql FROM sqlite_master WHERE type='view' AND name=?");
    $sth->execute($table);
    my $row = $sth->fetch;
    $sth->finish;
    return $row ? $row->[0] : undef;
  }

  return undef;
}

sub _split_key {
  my ($self, $key) = @_;
  if ($key =~ /^(.+)\.(.+)$/) {
    return ($1, $2);
  }
  return (undef, $key);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Introspect::DBI - DBI-based introspection via standard metadata APIs

=head1 VERSION

version 0.900002

=head1 DESCRIPTION

C<DBIO::Introspect::DBI> wraps DBI metadata APIs (C<column_info>,
C<primary_key>, C<foreign_key_info>, C<table_info>) into the normalized
contract defined in L<DBIO::Introspect::Base>.

Driver-specific introspectors (L<DBIO::PostgreSQL::Introspect>,
L<DBIO::SQLite::Introspect>, etc.) inherit from this when they want to
override with native queries for accuracy or features.

=head1 ATTRIBUTES

=head2 dbms_name

The DBI driver name (e.g., C<Pg>, C<SQLite>, C<mysql>). Auto-detected
from C<dbh> if not provided.

=head1 METHODS

=head2 table_keys

Returns all tables and views as C<[schema.]table> strings.

=head2 table_columns

    my \@names = $intro->table_columns($key);

Ordered list of column names for C<$key>.

=head2 table_columns_info

    my \%info = %{ $intro->table_columns_info($key) };

Hashref C<{ col_name => { data_type, size, is_nullable, default_value,
is_auto_increment, ... } }>.

=head2 table_pk_info

    my \@pk_cols = @{ $intro->table_pk_info($key) };

Ordered list of primary key column names.

=head2 table_uniq_info

    my \@constraints = @{ $intro->table_uniq_info($key) };

List of C<[ $constraint_name, \@col_names ]> pairs.

=head2 table_fk_info

    my \@fks = @{ $intro->table_fk_info($key) };

Each FK is a hashref:

    {
      local_columns  => [qw/author_id/],
      remote_table   => 'authors',
      remote_schema  => 'public',   # may be undef
      remote_columns => [qw/id/],   # may be [] (use remote PK)
      attrs          => {},
    }

=head2 table_is_view

Returns true if C<$key> is a view rather than a base table.

=head2 view_definition

SQL text of the view definition, or C<undef>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
