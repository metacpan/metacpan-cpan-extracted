package DBIO::MySQL::Introspect::Columns;
# ABSTRACT: Introspect MySQL/MariaDB columns

use strict;
use warnings;

use DBIO::MySQL::Introspect::Util ();



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

  my $sth = $dbh->prepare(q{
    SELECT
      table_name,
      column_name,
      ordinal_position,
      data_type,
      column_type,
      is_nullable,
      column_default,
      column_key,
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
    my $is_pk = ($row->{column_key} // '') eq 'PRI' ? 1 : 0;

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
      default_value     => $row->{column_default},
      is_auto_increment => $auto,
      is_pk             => $is_pk,
      # `pk_position` lets DBIO::Introspect::Base::table_pk_info sort
      # composite primary keys in the right order. Single-column PKs
      # always get position 1.
      pk_position       => $is_pk ? $row->{ordinal_position} : undef,
      character_set     => $row->{character_set_name},
      collation         => $row->{collation_name},
      comment           => $row->{column_comment},
      extra             => $extra,
    };
  }

  return \%columns;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Introspect::Columns - Introspect MySQL/MariaDB columns

=head1 VERSION

version 0.900001

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
C<extra>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
