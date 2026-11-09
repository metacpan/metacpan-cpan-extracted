package DBIO::ClickHouse::Introspect::Columns;
# ABSTRACT: Introspect ClickHouse columns via system.columns

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::ClickHouse::Introspect::Util ();



sub fetch {
  my ($class, $dbh, $tables, $database) = @_;

  my $sql = q{
    SELECT
      table,
      name,
      type,
      position,
      default_kind,
      default_expression,
      compression_codec,
      comment,
      is_in_sorting_key,
      is_in_partition_key
    FROM system.columns
    WHERE database = %s
    ORDER BY table, position
  };
  my @bind;
  if (defined $database) {
    $sql = sprintf $sql, '?';
    push @bind, $database;
  }
  else {
    $sql = sprintf $sql, 'currentDatabase()';
  }

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  # column name => 1-based key position, per table
  my %pk_position;
  for my $name (keys %$tables) {
    my $key = $tables->{$name}{primary_key_columns} || [];
    $pk_position{$name}{ $key->[$_] } = $_ + 1 for 0 .. $#$key;
  }

  my %columns;
  while (my $row = $sth->fetchrow_hashref) {
    my $table = $row->{table} // '';
    next unless exists $tables->{$table};

    my $name     = $row->{name};
    my $type     = $row->{type};
    my $position = $pk_position{$table}{$name};

    push @{ $columns{$table} }, {
      column_name   => $name,
      data_type     => $type,
      not_null      =>
        DBIO::ClickHouse::Introspect::Util->normalize_type($type)->{is_nullable} ? 0 : 1,
      default_kind  => _nonempty($row->{default_kind}),
      # The raw ClickHouse expression. DBIO::ClickHouse::Introspect turns it
      # into a portable default_value / literal ref at contract time.
      default_value => _nonempty($row->{default_expression}),
      is_pk         => $position ? 1 : 0,
      pk_position   => $position,
      is_in_sorting_key   => $row->{is_in_sorting_key}   ? 1 : 0,
      is_in_partition_key => $row->{is_in_partition_key} ? 1 : 0,
      position          => $row->{position},
      comment           => _nonempty($row->{comment}),
      compression_codec => _nonempty($row->{compression_codec}),
    };
  }

  return \%columns;
}

# ClickHouse returns '' (not NULL) for "absent" in these String columns, so an
# empty string has to be folded back to undef or every column would look like
# it carried a default, a comment and a codec.
sub _nonempty {
  my ($value) = @_;
  return undef unless defined $value && length $value;
  return $value;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Introspect::Columns - Introspect ClickHouse columns via system.columns

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches column metadata from C<system.columns>, scoped to one database and
filtered to the tables surfaced by L<DBIO::ClickHouse::Introspect::Tables>.

=head2 The raw type string is kept

C<data_type> holds the B<native> ClickHouse type exactly as
C<system.columns.type> reports it -- C<LowCardinality(Nullable(String))>, not
C<text>. Two reasons:

=over 4

=item * It is lossless. The portable normalization
(L<DBIO::ClickHouse::Introspect::Util/normalize_type>) is many-to-one in
places, so a model that stored only the portable form could not be compared
against the server byte-for-byte. The diff layer reads the model directly and
wants the exact string; L<DBIO::Introspect::Base>'s consumers go through
C<< DBIO::ClickHouse::Introspect->table_columns_info >>, which normalizes.

=item * It matches the family. L<DBIO::DuckDB::Introspect::Columns> likewise
stores C<VARCHAR(100)> and normalizes at contract time.

=back

C<not_null> is the one thing that must be derived here, because ClickHouse has
no nullability column in C<system.columns>: nullability is part of the type
(C<Nullable(T)>), and columns are B<NOT NULL by default>.

=head2 Primary key

ClickHouse has no primary-key constraint. C<is_pk> / C<pk_position> come from
C<primary_key_columns> on the table row -- the bare column names of the
MergeTree key, in key order. A column that only appears inside a key
B<expression> is not marked, because it cannot be named in a portable
C<set_primary_key>.

=head1 METHODS

=head2 fetch

    my $columns = DBIO::ClickHouse::Introspect::Columns->fetch($dbh, $tables);
    my $columns = DBIO::ClickHouse::Introspect::Columns->fetch($dbh, $tables, $database);

Given the tables hashref from L<DBIO::ClickHouse::Introspect::Tables>, returns
a hashref keyed by table name. Each value is an arrayref of column hashrefs in
C<position> order with keys: C<column_name>, C<data_type> (the native type
string), C<not_null>, C<default_kind>, C<default_value> (the raw default
B<expression>, not a Perl value), C<is_pk>, C<pk_position>,
C<is_in_sorting_key>, C<is_in_partition_key>, C<position>, C<comment>,
C<compression_codec>.

=head1 SEE ALSO

=over 4

=item * L<DBIO::ClickHouse::Introspect::Util> - the type parser used for C<not_null>

=item * L<DBIO::ClickHouse::Introspect> - normalizes these rows into the contract shape

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
