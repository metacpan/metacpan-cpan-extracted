package DBIO::SQLite::Diff::Rebuild;
# ABSTRACT: Diff operation that rebuilds a SQLite table

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::SQLite::Util qw(
  create_table_name_index quote_identifier sql_tokens token_identifier
);
use namespace::clean;


__PACKAGE__->mk_diff_accessors(qw/
  table_name table_sql copy_columns triggers reasons data_checks lossy_columns
/);


sub lossy { return scalar @{ $_[0]->lossy_columns // [] } ? 1 : 0 }




sub statements {
  my ($self) = @_;

  my $name     = $self->table_name;
  my $t        = quote_identifier($name);
  my $tmp_name = $name . '__dbio_rebuild';
  my $tmp      = quote_identifier($tmp_name);

  my $create = $self->_rename_create($self->table_sql, $name, $tmp_name);

  my @copy = map { quote_identifier($_) } @{ $self->copy_columns // [] };
  my $collist = join ', ', @copy;

  my @stmts = (
    'PRAGMA foreign_keys=OFF;',
    'PRAGMA legacy_alter_table=ON;',
    'SAVEPOINT dbio_rebuild;',
    "$create;",
  );
  push @stmts, sprintf "INSERT INTO %s (%s)\nSELECT %s FROM %s;",
    $tmp, $collist, $collist, $t
    if @copy;
  push @stmts,
    sprintf('DROP TABLE %s;', $t),
    sprintf('ALTER TABLE %s RENAME TO %s;', $tmp, $t),
    (map { "$_;" } @{ $self->triggers // [] }),
    'RELEASE dbio_rebuild;',
    'PRAGMA legacy_alter_table=OFF;',
    'PRAGMA foreign_keys=ON;';

  return @stmts;
}


sub as_sql {
  my ($self) = @_;
  return join "\n", $self->statements;
}

# Swap the leading table-name token in a CREATE TABLE statement for the
# temporary name, leaving the rest of the captured DDL untouched. The token is
# found by the lexer, so it is the name in whichever form sqlite_master stores
# it -- bare, "double-quoted" (also with a doubled quote inside, "a""b"),
# `back-ticked`, [bracketed] -- and never a longer name that begins with it.
# A statement whose name token is not this table's is left as it is.
sub _rename_create {
  my ($self, $sql, $name, $tmp_name) = @_;
  my @tokens = sql_tokens($sql);
  my $at     = create_table_name_index(\@tokens);
  return $sql
    unless defined $at && lc token_identifier(@{ $tokens[$at] }) eq lc $name;
  $tokens[$at][1] = quote_identifier($tmp_name);
  return join '', map { $_->[1] } @tokens;
}


sub summary {
  my ($self) = @_;
  my @reasons = @{ $self->reasons // [] };
  return sprintf '~ table rebuild: %s%s', $self->table_name,
    @reasons ? ' (' . join('; ', @reasons) . ')' : '';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Diff::Rebuild - Diff operation that rebuilds a SQLite table

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

SQLite's C<ALTER TABLE> cannot change a column's type, nullability, or
default in place. The only way to apply such a change is the documented
rebuild dance: create a new table with the desired shape under a temporary
name, copy the surviving data across, drop the original, and rename the new
table into its place.

L<DBIO::SQLite::Diff> also emits it for a table that gains a column
C<ADD COLUMN> cannot express -- C<UNIQUE>, C<PRIMARY KEY>, or a part in a
table constraint; see L<DBIO::SQLite::Diff::Column/Added columns> -- and for a
table whose primary key, C<UNIQUE> constraints, foreign keys, C<CHECK>s,
collations, generated expressions, C<WITHOUT ROWID> or C<STRICT> differ
between the two models, none of which C<ALTER TABLE> can change. The whole
list is under L<DBIO::SQLite::Diff/When a table is rebuilt>. Whatever the
cause, the op is the same; why it is there is in L</reasons>.

The new table is created from C<table_sql> -- the I<target> table's original
C<CREATE TABLE> statement as captured from C<sqlite_master> during
introspection -- with only the leading table-name token swapped for the
temporary name. The name is found whichever way the statement quotes it --
bare, as a database deployed by an earlier version has it, in double quotes
with a quote inside it doubled, in backticks, brackets or apostrophes
(L<DBIO::SQLite::Util/create_table_name_index>). Reusing the captured DDL
keeps the rebuild faithful: PRIMARY KEY, AUTOINCREMENT, inline foreign keys,
C<WITHOUT ROWID>, C<STRICT>, and column defaults all survive exactly as the
desired schema declared them (reconstructing them from the column model would
be lossy).

C<copy_columns> are the columns whose data is carried over: those present in
B<both> the old and the new table, without the ones that are B<generated> in
the new table (C<GENERATED ALWAYS AS>, C<VIRTUAL> or C<STORED>). SQLite
refuses to write to a generated column, and there is nothing to carry: the
new table computes it. A column that was generated and is a plain one now is
copied -- its values are data from here on. Added columns take their default,
dropped columns are left behind.

=head2 What hangs on the table

Dropping a table takes more with it than its rows, and renaming one is
checked against the rest of the schema. The rebuild deals with each:

=over 4

=item * B<Indexes> are dropped with the table. L<DBIO::SQLite::Diff> re-emits
C<CREATE INDEX> ops for the table's target indexes after this op.

=item * B<Triggers on the table> are dropped with it as well. C<triggers> holds
their C<CREATE TRIGGER> statements, as the B<live> table has them
(L<DBIO::SQLite::Introspect::Triggers>), and the rebuild runs each again once
the new table has the name. They come from the source because a schema cannot
declare a trigger; they are carried, not changed -- also where one names a
column the new table no longer has, which SQLite accepts when the trigger is
created. Only triggers in C<sqlite_master> are known: a C<TEMP> trigger on the
table is lost.

=item * B<Views that select from the table, and triggers on other tables that
name it>, are not touched by the C<DROP>, but they stop the C<RENAME>: SQLite
checks the whole schema when it renames a table, and at that moment the view
points at a table that is gone -- C<error in view ...: no such table>. The
rebuild therefore runs under C<PRAGMA legacy_alter_table=ON>. That pragma
gives C<ALTER TABLE ... RENAME> the behaviour it had before libsqlite 3.25:
the table gets its new name, and the rest of the schema is neither checked
nor rewritten. Nothing needs rewriting here -- views and triggers name the
table by the name it has again once the rename is done -- and so they work
afterwards as before.

=item * B<Foreign keys of other tables into the table> would fail the C<DROP>,
which deletes the rows first. The rebuild runs with C<PRAGMA
foreign_keys=OFF>.

=back

=head2 One unit

Between C<SAVEPOINT dbio_rebuild> and C<RELEASE dbio_rebuild> the rebuild is
all or nothing: rolled back to the savepoint, the original table is there
again with its rows, indexes and triggers. A savepoint and not C<BEGIN>, so
that it also nests in a transaction the caller has open.

The two pragmas stand outside it. C<PRAGMA foreign_keys> does nothing while a
transaction or savepoint is open, so it has to come first; and neither pragma
is undone by a rollback. This op is text and knows nothing of the connection
it will run on, so its last two statements are fixed --
C<legacy_alter_table=OFF>, C<foreign_keys=ON>, whatever the connection had --
and after a failure nothing of it has run past the failing statement. Both
gaps are closed by who runs it: L<DBIO::SQLite::Deploy/apply> rolls a failed
rebuild back and leaves both settings as it found them. Whoever runs the text
by other means has to do the same.

=head1 ATTRIBUTES

=head2 lossy_columns

An arrayref of the names of the columns whose change the rebuild applies and
that may alter or lose stored values: a column dropped, or one whose change
is lossy (L<DBIO::SQLite::Diff::Column/lossy>). L<DBIO::SQLite::Diff> fills
it; the statements do not depend on it.

=head2 data_checks

An arrayref of C<< { column => $name, kind => 'nulls' | 'added' } >>: what the
rebuild asks of the rows the table holds. C<nulls> is a column that becomes
C<NOT NULL> -- the copy writes its C<NULL>s into it; C<added> is a C<NOT NULL>
column without a default that the new table has and the old one had not -- a
copied row would hold C<NULL> in it. Either fails in SQLite for a table that
has such a row. L<DBIO::SQLite::Diff> fills it; L<DBIO::SQLite::Deploy/apply>
looks at the table before the first statement and refuses. The statements do
not depend on it.

=head2 reasons

An arrayref of what the two models differ in on this table, each a short
text: why the table is rebuilt. L<DBIO::SQLite::Diff> fills it and L</summary>
shows it; the statements do not depend on it.

=head1 METHODS

=head2 lossy

True when L</lossy_columns> names a column. The operation method of
L<DBIO::Diff::Base/destructive_operations>: the rebuild runs only with
C<< allow_destructive => 1 >> then (L<DBIO::Deploy::Base/apply>).

=head2 statements

    my @statements = $op->statements;

The statements of the rebuild in the order they have to run, each one
complete and closed by its semicolon. For a table C<item> with the columns
C<id> and C<name> on both sides and one trigger:

    PRAGMA foreign_keys=OFF;
    PRAGMA legacy_alter_table=ON;
    SAVEPOINT dbio_rebuild;
    CREATE TABLE "item__dbio_rebuild" ( ... );
    INSERT INTO "item__dbio_rebuild" ("id", "name")
    SELECT "id", "name" FROM "item";
    DROP TABLE "item";
    ALTER TABLE "item__dbio_rebuild" RENAME TO "item";
    CREATE TRIGGER item_ai AFTER INSERT ON item BEGIN ...; END;
    RELEASE dbio_rebuild;
    PRAGMA legacy_alter_table=OFF;
    PRAGMA foreign_keys=ON;

Every name is quoted (L<DBIO::SQLite::Util/quote_identifier>); what is between
the parentheses of the C<CREATE TABLE> is the captured statement, untouched,
and so is each trigger statement. The C<INSERT> is left out when there is no
column to copy.

A trigger statement has semicolons B<inside> it. That is why this is a list:
the statements can be run one by one without anybody cutting text at
semicolons.

=head2 as_sql

L</statements>, one after the other: a complete script, as the C<sqlite3>
shell takes it, or C<< $dbh->do >> with C<sqlite_allow_multiple_statements>.
It cannot be cut back into statements at its semicolons once a trigger is in
it; ask L</statements> for those.

=head2 summary

C<~ table rebuild: name>, followed in parentheses by the L</reasons> of the
rebuild, separated by semicolons:

    ~ table rebuild: item (column val: NOT NULL no -> yes; foreign key (owner_id) -> owner (id) ON DELETE CASCADE added)

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
