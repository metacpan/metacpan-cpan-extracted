package DBIO::DuckDB::DDL::Emit;
# ABSTRACT: Single source of DuckDB DDL statement shape

use strict;
use warnings;

use DBIO::SQL::Util qw(_quote_ident);
use Exporter 'import';

our @EXPORT_OK = qw(
  column_def pk_clause unique_clause fk_clause
  create_table create_index create_sequence
);



sub column_def {
  my (%a) = @_;
  my $def = sprintf '%s %s', _quote_ident($a{name}), ($a{type} // 'VARCHAR');
  $def .= ' NOT NULL' if $a{not_null};
  $def .= " DEFAULT $a{default}" if defined $a{default};
  return $def;
}


sub pk_clause {
  my (@cols) = @_;
  return sprintf 'PRIMARY KEY (%s)', join ', ', map { _quote_ident($_) } @cols;
}


sub unique_clause {
  my (@cols) = @_;
  return sprintf 'UNIQUE (%s)', join ', ', map { _quote_ident($_) } @cols;
}


sub fk_clause {
  my (%a) = @_;
  return sprintf 'FOREIGN KEY (%s) REFERENCES %s(%s)',
    join(', ', map { _quote_ident($_) } @{ $a{from} }),
    _quote_ident($a{to_table}),
    join(', ', map { _quote_ident($_) } @{ $a{to} });
}


sub create_table {
  my ($name, @defs) = @_;
  return sprintf "CREATE TABLE %s (\n%s\n);",
    _quote_ident($name), join ",\n", map { "  $_" } @defs;
}


sub create_index {
  my (%a) = @_;
  return sprintf 'CREATE %sINDEX %s ON %s (%s);',
    ($a{unique} ? 'UNIQUE ' : ''),
    _quote_ident($a{name}), _quote_ident($a{table}),
    join(', ', map { _quote_ident($_) } @{ $a{columns} // [] });
}


sub create_sequence {
  my (%a) = @_;
  my $sql = sprintf 'CREATE SEQUENCE IF NOT EXISTS %s', _quote_ident($a{name});
  $sql .= " START $a{start}" if defined $a{start};
  return "$sql;";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::DDL::Emit - Single source of DuckDB DDL statement shape

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

The DuckDB DDL string templates -- column definitions, table/index/sequence
statements, and the inline PK/UNIQUE/FK clauses -- live here so that the two
producers of DDL agree on syntax char-for-char:

=over 4

=item * L<DBIO::DuckDB::DDL> renders the desired schema from DBIO Result
classes (C<column_info> hashrefs).

=item * L<DBIO::DuckDB::Diff::Table> / L<DBIO::DuckDB::Diff::Column> /
L<DBIO::DuckDB::Diff::Index> render CREATE / ALTER statements from an
introspected model.

=back

Each caller owns the field-extraction adapter for its own input shape
(DBIO metadata vs introspected model) and feeds normalized pieces here.
These functions are pure: identifiers are quoted via L<DBIO::SQL::Util>,
nothing else is interpreted. Clauses are returned B<without> indentation;
L</create_table> indents the body uniformly.

=func column_def

    column_def(name => $n, type => $t, not_null => $bool, default => $sql);

Renders C<"name" TYPE [NOT NULL] [DEFAULT $sql]>. C<default> is emitted
verbatim -- the caller is responsible for quoting/escaping it (the two
producers derive defaults very differently). Pass C<undef> for no default.

=func pk_clause

    pk_clause(@columns);

=func unique_clause

    unique_clause(@columns);

=func fk_clause

    fk_clause(from => \@local, to_table => $t, to => \@remote);

=func create_table

    create_table($table_name, @clause_strings);

Wraps the clauses (column defs, PK, UNIQUE, FK -- all unindented) in a
C<CREATE TABLE> statement, indenting each clause by two spaces.

=func create_index

    create_index(name => $n, table => $t, columns => \@cols, unique => $bool);

=func create_sequence

    create_sequence(name => $n);
    create_sequence(name => $n, start => 1000000);

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
