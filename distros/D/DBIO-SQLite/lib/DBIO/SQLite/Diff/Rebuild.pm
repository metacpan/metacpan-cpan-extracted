package DBIO::SQLite::Diff::Rebuild;
# ABSTRACT: Diff operation that rebuilds a SQLite table

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::SQL::Util qw(_quote_ident);
use namespace::clean;


__PACKAGE__->mk_diff_accessors(qw/table_name table_sql copy_columns/);


sub as_sql {
  my ($self) = @_;

  my $name     = $self->table_name;
  my $t        = _quote_ident($name);
  my $tmp_name = $name . '__dbio_rebuild';
  my $tmp      = _quote_ident($tmp_name);

  my $create = $self->_rename_create($self->table_sql, $name, $tmp_name);

  my @copy = map { _quote_ident($_) } @{ $self->copy_columns // [] };
  my $collist = join ', ', @copy;

  my @stmts = (
    'PRAGMA foreign_keys=OFF;',
    "$create;",
  );
  push @stmts, sprintf "INSERT INTO %s (%s)\nSELECT %s FROM %s;",
    $tmp, $collist, $collist, $t
    if @copy;
  push @stmts,
    sprintf('DROP TABLE %s;', $t),
    sprintf('ALTER TABLE %s RENAME TO %s;', $tmp, $t),
    'PRAGMA foreign_keys=ON;';

  return join "\n", @stmts;
}

# Swap the leading table-name token in a CREATE TABLE statement for the
# temporary name, leaving the rest of the captured DDL untouched. Handles the
# bare, "double-quoted", `back-ticked`, and [bracketed] identifier forms that
# sqlite_master may store.
sub _rename_create {
  my ($self, $sql, $name, $tmp_name) = @_;
  my $repl = _quote_ident($tmp_name);
  $sql =~ s{
    ^(\s*CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?)
    (?: "\Q$name\E" | `\Q$name\E` | \[\Q$name\E\] | \Q$name\E )
  }{$1$repl}xi;
  return $sql;
}


sub summary {
  my ($self) = @_;
  return sprintf '~ table rebuild: %s', $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Diff::Rebuild - Diff operation that rebuilds a SQLite table

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

SQLite's C<ALTER TABLE> cannot change a column's type, nullability, or
default in place. The only way to apply such a change is the documented
rebuild dance: create a new table with the desired shape under a temporary
name, copy the surviving data across, drop the original, and rename the new
table into its place.

The new table is created from C<table_sql> -- the I<target> table's original
C<CREATE TABLE> statement as captured from C<sqlite_master> during
introspection -- with only the leading table-name token swapped for the
temporary name. Reusing the captured DDL keeps the rebuild faithful: PRIMARY
KEY, AUTOINCREMENT, inline foreign keys, C<WITHOUT ROWID>, C<STRICT>, and
column defaults all survive exactly as the desired schema declared them
(reconstructing them from the column model would be lossy).

C<copy_columns> are the column names present in B<both> the old and new
table, so only those carry data over (added columns take their default,
dropped columns are left behind).

The rebuild brackets itself with C<PRAGMA foreign_keys=OFF> / C<ON>: the
statements run one at a time with autocommit on (see
L<DBIO::Deploy::Base/_execute_ddl>), so dropping a table that other tables
reference is safe within the bracketed window.

Indexes on the rebuilt table are dropped with it; L<DBIO::SQLite::Diff>
re-emits C<CREATE INDEX> ops for the table's target indexes after this op.

=head1 METHODS

=head2 as_sql

Returns the multi-statement rebuild SQL (semicolon-terminated statements, as
expected by C<_split_statements>).

=head2 summary

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
