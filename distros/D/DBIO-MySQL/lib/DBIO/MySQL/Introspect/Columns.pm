package DBIO::MySQL::Introspect::Columns;
# ABSTRACT: Introspect MySQL/MariaDB columns

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::MySQL::Introspect::Util ();
use DBIO::MySQL::DefaultValue ();



sub fetch {
  my ($class, $dbh, $tables) = @_;
  my %columns;

  # On MySQL 8 the information_schema result-column labels come back UPPERCASE
  # regardless of the case written in the SELECT, while MariaDB returns them
  # lowercase. Force lowercase hash keys for this fetch so the $row->{lc} reads
  # below resolve on both engines. The sth captures FetchHashKeyName from the
  # dbh at prepare time, so it must be set before prepare (Tables.pm sidesteps
  # this by aliasing every column, which echoes the alias case verbatim).
  local $dbh->{FetchHashKeyName} = 'NAME_lc';

  # Only a MariaDB that reports COLUMN_DEFAULT as an expression says "no
  # default" with the text NULL; from a MySQL that text is a default (see
  # default_value in the POD above).
  my $null_is_keyword = _default_is_expression(scalar $dbh->selectrow_array('SELECT VERSION()'));

  # is_pk comes from the index PRIMARY, not from COLUMN_KEY: both servers
  # report COLUMN_KEY = 'PRI' for the first column of a UNIQUE key over NOT
  # NULL columns when the table has no primary key at all. The index name is
  # what Introspect::Indexes reads as origin 'pk' as well.
  my %in_pk;
  my $pk_sth = $dbh->prepare(q{
    SELECT table_name, column_name, seq_in_index
    FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND index_name = 'PRIMARY'
  });
  $pk_sth->execute;
  while (my $row = $pk_sth->fetchrow_hashref) {
    $in_pk{ $row->{table_name} }{ $row->{column_name} } = $row->{seq_in_index};
  }

  my $sth = $dbh->prepare(q{
    SELECT
      table_name,
      column_name,
      ordinal_position,
      data_type,
      column_type,
      is_nullable,
      column_default,
      extra,
      character_set_name,
      collation_name,
      column_comment
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
    ORDER BY table_name, ordinal_position
  });
  $sth->execute;

  while (my $row = $sth->fetchrow_hashref) {
    next unless DBIO::MySQL::Introspect::Util->keep_table($tables, $row->{table_name});

    my $extra = $row->{extra} // '';
    my $auto  = ($extra =~ /\bauto_increment\b/i) ? 1 : 0;
    my $pk_pos = $in_pk{ $row->{table_name} }{ $row->{column_name} };
    my $is_pk  = defined $pk_pos ? 1 : 0;

    my $default = $row->{column_default};
    undef $default if $null_is_keyword && defined $default && $default eq 'NULL';
    ($default, my $is_expression) = DBIO::MySQL::DefaultValue::catalog_default(
      raw                => $default,
      extra              => $extra,
      data_type          => $row->{data_type},
      mariadb_expression => $null_is_keyword,
    );

    push @{ $columns{ $row->{table_name} } }, {
      column_name       => $row->{column_name},
      data_type         => $row->{data_type},
      column_type       => $row->{column_type},
      # `size` is the canonical companion to `data_type`: extracted from
      # `column_type`'s parenthesised number (varchar(100) -> 100,
      # int(11) -> 11, decimal(10,2) -> 10). DBIO::Introspect::Base
      # relies on this to size columns it builds.
      size              => DBIO::MySQL::Introspect::Util->column_size($row->{column_type}),
      not_null          => (uc($row->{is_nullable} // '') eq 'NO') ? 1 : 0,
      default_value     => $default,
      default_is_expression => $is_expression,
      on_update         => DBIO::MySQL::DefaultValue::catalog_on_update($extra),
      is_auto_increment => $auto,
      is_pk             => $is_pk,
      # `pk_position` lets DBIO::Introspect::Base::table_pk_info sort
      # composite primary keys in the right order: the position in the key
      # (seq_in_index), not the position of the column in the table
      # (karr k107). Single-column PKs always get position 1.
      pk_position       => $pk_pos,
      character_set     => $row->{character_set_name},
      collation         => $row->{collation_name},
      comment           => $row->{column_comment},
      extra             => $extra,
    };
  }

  return \%columns;
}

# True for a server that reports COLUMN_DEFAULT as an expression: a MariaDB
# from 10.2.7 on (MDEV-13132), going by the version string it answers.
sub _default_is_expression {
  my ($version) = @_;
  return 0 unless ($version // '') =~ /mariadb/i;
  my ($major, $minor, $patch) = $version =~ /(\d+)\.(\d+)\.(\d+)/ or return 0;
  return ($major <=> 10 || $minor <=> 2 || $patch <=> 7) >= 0 ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Introspect::Columns - Introspect MySQL/MariaDB columns

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches column metadata from C<information_schema.columns>, scoped to the
current C<DATABASE()> and filtered to the tables surfaced by
L<DBIO::MySQL::Introspect::Tables>. The C<column_type> size parser and the
C<$tables> filter are the shared helpers in
L<DBIO::MySQL::Introspect::Util>.

=head1 METHODS

=head2 fetch

    my $columns = DBIO::MySQL::Introspect::Columns->fetch($dbh, $tables);

Given the tables hashref from L<DBIO::MySQL::Introspect::Tables>, returns a
hashref keyed by table name. Each value is an arrayref of column hashrefs
(in C<ordinal_position> order) with keys: C<column_name>, C<data_type>,
C<column_type>, C<size>, C<not_null>, C<default_value>, C<is_auto_increment>,
C<is_pk>, C<pk_position>, C<character_set>, C<collation>, C<comment>,
C<extra>. C<pk_position> is the position of the column in the primary key
(C<seq_in_index>, 1 for a single-column key), not its position in the table.

C<default_value> is C<COLUMN_DEFAULT>, and C<undef> for a column that has no
default; C<default_is_expression> is C<1> when it is an expression
(C<CURRENT_TIMESTAMP>, C<uuid()>) and C<0> when it is a value, which a diff
writes as a string literal (L<DBIO::MySQL::DefaultValue>). The two servers
report it differently:

=over 4

=item * MySQL reports the value itself -- C<abc> for C<DEFAULT 'abc'> -- and
SQL C<NULL> for a column without a default.

=item * MariaDB, from 10.2.7 on, reports an expression: a string in quotes
(C<'abc'>), a function the way it writes it (C<current_timestamp()>), and for a
nullable column without a default, or with C<DEFAULT NULL>, the keyword
C<NULL> -- a text of four letters. A C<NOT NULL> column without a default is
SQL C<NULL> there as well.

=back

That keyword is read as what it says, so C<default_value> is C<undef> on either
server for a column without a default. A literal comes back as its value on
both servers -- MariaDB's quotes are taken off and its escapes undone -- and an
expression as its text, told apart by C<default_is_expression>
(L<DBIO::MySQL::DefaultValue/catalog_default>). The text C<NULL> from a MySQL
stays, because there it is the string a column defaults to (C<DEFAULT 'NULL'>,
which MariaDB reports as C<'NULL'> in quotes and is read as C<NULL>, a value).

Which of the two the server is, it says in C<SELECT VERSION()> -- what
L<DBIO::MySQL::Storage/_is_mariadb> asks through a storage is asked of the
handle here, because this reader has no storage. L<DBD::mysql> and
L<DBD::MariaDB> both hand on what the server reports, so the driver in use
says nothing about it.

C<on_update> is the C<ON UPDATE> of the column, read from C<EXTRA> and spelled
the same on both servers (C<CURRENT_TIMESTAMP>, C<CURRENT_TIMESTAMP(6)>), or
C<undef> for a column without one; the key is there on every column
(L<DBIO::MySQL::DefaultValue/catalog_on_update>).

C<is_pk> is true for the columns of the index C<PRIMARY> in
C<information_schema.statistics>. C<COLUMN_KEY> is not used for it: both servers
report C<PRI> there for the first column of a C<UNIQUE> key over C<NOT NULL>
columns in a table that has no primary key.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
