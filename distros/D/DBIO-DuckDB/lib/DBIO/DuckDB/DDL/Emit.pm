package DBIO::DuckDB::DDL::Emit;
# ABSTRACT: Single source of DuckDB DDL statement shape

use strict;
use warnings;

our $VERSION = '0.900004';

use Exporter 'import';

our @EXPORT_OK = qw(
  quote_ident quote_table split_table column_def pk_clause unique_clause fk_clause
  create_table create_index create_sequence
);



sub quote_ident {
  my ($name) = @_;
  $name =~ s/"/""/g;
  return qq{"$name"};
}


sub split_table {
  my ($name) = @_;
  return ($1, $2) if $name =~ /\A([^.]+)\.([^.]+)\z/;
  return (undef, $name);
}


sub quote_table {
  my ($name) = @_;
  my ($schema, $table) = split_table($name);
  return defined $schema
    ? quote_ident($schema) . '.' . quote_ident($table)
    : quote_ident($table);
}


sub column_def {
  my (%a) = @_;
  my $def = sprintf '%s %s', quote_ident($a{name}), ($a{type} // 'VARCHAR');
  $def .= ' NOT NULL' if $a{not_null};
  $def .= " DEFAULT $a{default}" if defined $a{default};
  return $def;
}


sub pk_clause {
  my (@cols) = @_;
  return sprintf 'PRIMARY KEY (%s)', join ', ', map { quote_ident($_) } @cols;
}


sub unique_clause {
  my (@cols) = @_;
  return sprintf 'UNIQUE (%s)', join ', ', map { quote_ident($_) } @cols;
}


sub fk_clause {
  my (%a) = @_;
  my $sql = sprintf 'FOREIGN KEY (%s) REFERENCES %s(%s)',
    join(', ', map { quote_ident($_) } @{ $a{from} }),
    quote_table($a{to_table}),
    join(', ', map { quote_ident($_) } @{ $a{to} });
  $sql .= " ON DELETE $a{on_delete}" if defined $a{on_delete};
  $sql .= " ON UPDATE $a{on_update}" if defined $a{on_update};
  return $sql;
}


sub create_table {
  my ($name, @defs) = @_;
  return sprintf "CREATE TABLE %s (\n%s\n);",
    quote_table($name), join ",\n", map { "  $_" } @defs;
}


sub create_index {
  my (%a) = @_;
  # An expression is the whole list, as written; no column is quoted then.
  # An element of columns that is wrapped in parentheses is the expression
  # of an introspected index and goes in as it is.
  my $list = defined $a{expression}
    ? $a{expression}
    : join(', ', map { /^\(/ ? $_ : quote_ident($_) } @{ $a{columns} // [] });
  return sprintf 'CREATE %sINDEX %s ON %s (%s);',
    ($a{unique} ? 'UNIQUE ' : ''),
    quote_ident($a{name}), quote_table($a{table}), $list;
}


sub create_sequence {
  my (%a) = @_;
  my $sql = sprintf 'CREATE SEQUENCE IF NOT EXISTS %s', quote_table($a{name});
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

version 0.900004

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
These functions are pure: identifiers are quoted by L</quote_ident>,
nothing else is interpreted. Clauses are returned B<without> indentation;
L</create_table> indents the body uniformly.

=head1 METHODS

=head2 quote_ident

    my $sql = sprintf 'DROP TABLE %s;', quote_ident($table_name);

A name as DuckDB takes it for an identifier: between double quotes, every
double quote inside it doubled. It is B<always> quoted, whatever it looks like:
a reserved word (C<order>, C<group>, C<end>) has the same letters as C<item>,
and written bare it is a syntax error. DuckDB keeps the letter case of a
quoted name and matches names case-insensitively either way, so quoting
changes no object that is meant. This is the one quoter of the driver's DDL
and diff statements.

=head2 split_table

    my ($schema, $table) = split_table('other.t');   # ('other', 't')
    my ($schema, $table) = split_table('t');         # (undef, 't')

A table name with one dot is a table of a schema: C<other.t> is table C<t> of
schema C<other>. Anything else is a plain name, a dot included.

=head2 quote_table

    quote_table('other.t');   # "other"."t"
    quote_table('t');         # "t"

A table name quoted for a statement, each part by L</quote_ident>.

=head2 column_def

    column_def(name => $n, type => $t, not_null => $bool, default => $sql);

Renders C<"name" TYPE [NOT NULL] [DEFAULT $sql]>. C<default> is emitted
verbatim -- the caller is responsible for quoting/escaping it (the two
producers derive defaults very differently). Pass C<undef> for no default.

=head2 pk_clause

    pk_clause(@columns);

=head2 unique_clause

    unique_clause(@columns);

=head2 fk_clause

    fk_clause(from => \@local, to_table => $t, to => \@remote);
    fk_clause(from => \@local, to_table => $t, to => \@remote,
              on_delete => 'RESTRICT', on_update => 'NO ACTION');

C<on_delete> and C<on_update> are written as given, after the C<REFERENCES>
part; the caller has checked them, DuckDB takes C<RESTRICT> and C<NO ACTION>
only.

=head2 create_table

    create_table($table_name, @clause_strings);

Wraps the clauses (column defs, PK, UNIQUE, FK -- all unindented) in a
C<CREATE TABLE> statement, indenting each clause by two spaces.

=head2 create_index

    create_index(name => $n, table => $t, columns => \@cols, unique => $bool);
    create_index(name => $n, table => $t, expression => 'a, lower(b)');

An C<expression> is written as the whole list between the parentheses and
replaces C<columns>.

=head2 create_sequence

    create_sequence(name => $n);
    create_sequence(name => $n, start => 1000000);

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
