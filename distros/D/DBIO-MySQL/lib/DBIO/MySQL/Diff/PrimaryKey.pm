package DBIO::MySQL::Diff::PrimaryKey;
# ABSTRACT: Diff operations for MySQL/MariaDB primary keys

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use Exporter 'import';
use DBIO::MySQL::Identifier qw(quote_ident quote_table_in);
use DBIO::MySQL::Diff::Column ();

our @EXPORT_OK = ('primary_key_columns');

__PACKAGE__->mk_diff_accessors(qw(
  table_name columns old_columns with_columns database
));



sub primary_key_columns {
  my ($columns) = @_;
  my @pk = grep { $_->{is_pk} } @{ $columns // [] };
  # pk_position only when every column of the key has one; sort is stable
  if (!grep { !defined $_->{pk_position} } @pk) {
    @pk = sort { $a->{pk_position} <=> $b->{pk_position} } @pk;
  }
  return map { $_->{column_name} } @pk;
}


sub diff {
  my ($class, $source, $target, $source_tables, $target_tables) = @_;
  $source //= {}; $target //= {};
  $source_tables //= {}; $target_tables //= {};

  my @ops;
  for my $table (sort keys %$target_tables) {
    next unless exists $source_tables->{$table};
    my @new = primary_key_columns($target->{$table});
    my @was = primary_key_columns($source->{$table});
    # the key of a column that goes is shortened by the server, and gone with
    # its last column: what is left of it is the key this statement meets
    my %stay = map { $_->{column_name} => 1 } @{ $target->{$table} // [] };
    my @old = grep { $stay{$_} } @was;
    next if join("\0", @old) eq join("\0", @new);
    if (@new) {
      push @ops, $class->new(
        action => (@old ? 'replace' : 'add'), table_name => $table,
        columns => \@new, old_columns => \@was,
      );
    }
    else {
      push @ops, $class->new(
        action => 'drop', table_name => $table, columns => [], old_columns => \@was,
      );
    }
  }
  return @ops;
}


sub as_sql {
  my ($self) = @_;
  my $tbl = quote_table_in($self->database, $self->table_name);
  return "ALTER TABLE $tbl DROP PRIMARY KEY;" if $self->action eq 'drop';
  return sprintf 'ALTER TABLE %s %s%sADD PRIMARY KEY (%s);',
    $tbl,
    join('', map { $_->add_clause(1) . ', ' } @{ $self->with_columns // [] }),
    ($self->action eq 'replace' ? 'DROP PRIMARY KEY, ' : ''),
    join(', ', map { quote_ident($_) } @{ $self->columns });
}


sub summary {
  my ($self) = @_;
  return sprintf '  -pk: DROP PRIMARY KEY on %s (was %s)', $self->table_name, join(', ', @{ $self->old_columns })
    if $self->action eq 'drop';
  return sprintf '  ~primary key: %s on %s', join(', ', @{ $self->columns }), $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Diff::PrimaryKey - Diff operations for MySQL/MariaDB primary keys

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents the primary key of a table that is in both models: C<ALTER TABLE
... ADD PRIMARY KEY> for a table that has none (action C<add>), C<ALTER TABLE
... DROP PRIMARY KEY, ADD PRIMARY KEY> for a table whose key is composed
differently (action C<replace>, with C<old_columns>), and C<ALTER TABLE ...
DROP PRIMARY KEY> for a table whose target has no key at all (action C<drop>,
a destructive operation: the summary names it and the columns the key had). The
key of a table the diff creates is written into its C<CREATE TABLE> by
L<DBIO::MySQL::Diff::Table>, and that of a table the diff drops goes with it.
The PRIMARY index is no index of L<DBIO::MySQL::Diff::Index>, and C<is_pk> is no
field of the column comparison, so the key is compared and written here.

The key is the list of the columns whose C<is_pk> is true, in the order of
C<pk_position>, the position in the key (the introspection reads it from
C<seq_in_index>, C<target_from_compiled> from the order of the primary key of
the schema): the same columns in another order are another key, and the server
indexes them differently. A model without C<pk_position> is read in the order
of the table. A key whose columns all go with the diff is dropped by the server
with the last of them, and no statement is written for it; of a key that loses
only some of its columns the rest is the key the server holds when this
statement runs.

The two statements of a C<replace> are one C<ALTER TABLE>. Measured on MySQL
8.0 and MariaDB 11.8: an C<AUTO_INCREMENT> column has to be a key of the table
at every moment, and a C<DROP PRIMARY KEY> of its own is refused (1075) where
the same drop together with the new key is taken -- as long as the
C<AUTO_INCREMENT> column is the first column of the new key. An C<AUTO_INCREMENT> column that leaves the key, or is not the first column
of the new one, is no key of the table at that moment and the statement is
refused (1075) -- unless another index over it, starting with it, exists: the
UNIQUE index the target has over that column is created before the key
(L<DBIO::MySQL::Diff>). A column whose target has no such index is
no valid schema (a table can have an C<AUTO_INCREMENT> column only as a key),
which the deploy refuses when it builds the target. The columns of a
new key that are nullable become C<NOT NULL> by the statement itself (a
column holding NULL, or rows that repeat, make the server refuse it, as they
should). The same goes for a column that is new: an C<AUTO_INCREMENT> column of
the key that the diff adds is part of that one statement (C<with_columns>, the
C<ADD COLUMN> operations it takes over from L<DBIO::MySQL::Diff::Column>), the
server refusing it without its key.

The key of the source is dropped when the target has none. An
C<AUTO_INCREMENT> column of that key has to be released first, the server
refusing the plain drop (1075); L<DBIO::MySQL::Diff> writes the C<MODIFY>
without the attribute before the drop (the column diff has it anyway where the
target column does not keep the attribute) and, where the target keeps it on a
column with a key of another kind, gives it back after that key exists.

The server refuses to drop, or to change the start of, a primary key that a
foreign key of the table or a foreign key into the table needs as its index
(MySQL 1553, MariaDB errno 150). L<DBIO::MySQL::Diff> drops those foreign keys
before the statement and adds them after it, unchanged, and refuses a foreign
key the target declares over columns that the target has no key over any more
(L<DBIO::Exception>, naming table and constraint) instead of dropping it
unseen.

L<DBIO::MySQL::Diff> puts the operation after the column changes, where the
columns of the key exist, and before the indexes that are created and the
foreign keys that are added. A column that gains C<AUTO_INCREMENT> and is in
the key is the one exception: its C<MODIFY COLUMN> needs the key, so the key
comes first.

=head1 METHODS

=head2 primary_key_columns

    my @names = primary_key_columns($columns);

The names of the columns of the primary key in the order of the key, from the
C<columns> list of one table of a model.

=head2 diff

    my @ops = DBIO::MySQL::Diff::PrimaryKey->diff(
      $source_columns, $target_columns, $source_tables, $target_tables);

The C<columns> and C<tables> sections of the two models. Only a table that is
in both models is looked at.

=head2 as_sql

The C<ALTER TABLE> statement, every name quoted with
L<DBIO::MySQL::Identifier/quote_ident>.

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
