package DBIO::MSSQL::Diff::PrimaryKey;
# ABSTRACT: Diff operations for MSSQL primary keys

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Exception ();
use DBIO::MSSQL::DDL qw(_quote_ident _quote_table _constraint_name);
use DBIO::MSSQL::Diff::Table ();


__PACKAGE__->mk_diff_accessors(qw/table_name constraint_name columns dropped_for_good clustered/);

# [ column names in key order ], from the column list of a table
sub _key_columns {
  my ($cols) = @_;
  return map { $_->{column_name} }
    sort { ($a->{pk_position} || 0) <=> ($b->{pk_position} || 0) }
    grep { $_->{is_pk} } @{ $cols // [] };
}


sub diff {
  my ($class, $source, $target, $source_tables, $target_tables, $column_ops) = @_;
  $source //= {};
  $target //= {};
  my %is_view = map { $_ => 1 }
    DBIO::MSSQL::Diff::Table->view_names($source_tables, $target_tables);

  my @ops;
  for my $table (sort keys %$target) {
    next if $is_view{$table} || !$source->{$table};
    my @want = _key_columns($target->{$table});
    my @have = _key_columns($source->{$table});
    next unless @want || @have;

    my $changed = join("\0", @have) ne join("\0", @want);

    # CLUSTERED or NONCLUSTERED: compared when both models know it. The classes
    # create the key clustered (install_ddl), so a live key that is not is
    # replaced -- the same way as a key with other columns. The server cannot
    # change it in place, and ADD PRIMARY KEY without the word makes the key
    # NONCLUSTERED, silently, while a clustered index stands (measured).
    my ($have_cl, $want_cl);
    if (@have && @want) {
      ($have_cl) = map { $_->{pk_clustered} } grep { $_->{is_pk} } @{ $source->{$table} };
      ($want_cl) = map { $_->{pk_clustered} } grep { $_->{is_pk} } @{ $target->{$table} };
      $changed ||= defined $have_cl && defined $want_cl && !$have_cl != !$want_cl;
    }
    if (!$changed && @have) {
      my %key = map { $_ => 1 } @have;
      $changed = grep {
        $_->table_name eq $table && $key{ $_->column_name } && $_->unbinds_dependents
      } @{ $column_ops // [] };
    }
    next unless $changed;

    if (@have) {
      my ($live) = grep { $_->{is_pk} } @{ $source->{$table} };
      my $name = $live->{pk_constraint_name};
      DBIO::Exception->throw(sprintf
        "DBIO::MSSQL: the primary key of table '%s' (%s) cannot be dropped: "
        . "Transact-SQL drops a key by constraint name and the live column "
        . "info carries no pk_constraint_name", $table, join(', ', @have))
        unless defined $name && length $name;
      push @ops, $class->new(action => 'drop', table_name => $table,
        constraint_name => $name, columns => [ @have ], dropped_for_good => !@want);
    }
    next unless @want;
    push @ops, $class->new(action => 'create', table_name => $table,
      constraint_name => _constraint_name('PK', $table), columns => [ @want ],
      clustered => $want_cl);
  }
  return @ops;
}


sub as_sql {
  my ($self) = @_;
  my $tbl  = _quote_table($self->table_name);
  my $name = _quote_ident($self->constraint_name);
  return sprintf 'ALTER TABLE %s DROP CONSTRAINT %s;', $tbl, $name
    if $self->action eq 'drop';
  my $cl = !defined $self->clustered ? ''
    : $self->clustered ? 'CLUSTERED ' : 'NONCLUSTERED ';
  return sprintf 'ALTER TABLE %s ADD CONSTRAINT %s PRIMARY KEY %s(%s);',
    $tbl, $name, $cl, join ', ', map { _quote_ident($_) } @{ $self->columns };
}


sub summary {
  my ($self) = @_;
  return sprintf '  %sPRIMARY KEY DROPPED: %s (%s) -- the classes declare no primary key for it',
    $self->summary_prefix, $self->table_name, join ', ', @{ $self->columns }
    if $self->dropped_for_good;
  return sprintf '  %sprimary key: %s (%s)',
    $self->summary_prefix, $self->table_name, join ', ', @{ $self->columns };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Diff::PrimaryKey - Diff operations for MSSQL primary keys

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Primary-key operations for tables that exist on both sides. The key of a new
table is part of its C<CREATE TABLE> (L<DBIO::MSSQL::Diff::Table>); the key of
a dropped table goes with it. The model carries no key object: it is read from
the columns, C<is_pk> and C<pk_position> (the position in the key, so the
order of a composite key counts), and the live name from C<pk_constraint_name>
(L<DBIO::MSSQL::Introspect::Columns>).

A key that differs -- other columns, or the same columns in another order --
becomes a pair, because a table has one primary key and SQL Server refuses the
second (measured):

    ALTER TABLE t DROP CONSTRAINT <live name>;
    ALTER TABLE t ADD CONSTRAINT PK_t PRIMARY KEY (a, b);

The name of a key the diff adds is C<PK_E<lt>tableE<gt>>, the one
L<DBIO::MSSQL::DDL/install_ddl> writes. The name of a key already in the
database is not compared: the server named it, and two databases that hold the
same key under different names are the same.

The key is compared as C<CLUSTERED> or C<NONCLUSTERED> as well
(C<pk_clustered>, L<DBIO::MSSQL::Introspect::Columns>), when both models carry
it: the classes create the key clustered, so a live nonclustered key is
dropped and added again with the same columns, and the added key says
C<CLUSTERED> out loud -- without the word the server makes it nonclustered
while a clustered index stands on the table, and the next diff would find the
difference again (measured). The clustered index the live table may
have beside a nonclustered key is no obstacle: the classes refuse a clustered
index next to a key (Msg 1902), so the target has none, and the diff drops it
(or re-creates it nonclustered) before the key is added.

A key is dropped and added again, without a difference in its columns, when
one of its columns changes its type: the server refuses C<ALTER COLUMN> to
another type on a key column (a width change of C<nvarchar> works), see
L<DBIO::MSSQL::Diff::Column/unbinds_dependents>.

B<A target without a key drops the live key> (maintainer's decision, as
L<DBIO::Sybase::Diff> does, and as a foreign key the classes do not declare is
dropped: what the classes do not declare does not stay). L</summary> names it
on a line of its own, C<PRIMARY KEY DROPPED>. The server refuses to drop a key
a foreign key references (measured), so the foreign keys that reference it are
dropped first by L<DBIO::MSSQL::Diff>; if the classes declare one of them, it
could not be created afterwards (no primary or candidate key in the referenced
table, measured) and the diff refuses with a L<DBIO::Exception> naming table and
foreign key instead of dropping a declared foreign key. A unique constraint or
unique index over the same columns is a candidate key and lets the foreign key
stand.

L<DBIO::MSSQL::Diff> places the operations: the drops with the other drops
before the column phase, the adds after it (a column that becomes the key has
to be C<NOT NULL> first, which the server demands), and it drops and adds the
foreign keys that reference the key around it.

=head1 METHODS

=head2 diff

    my @ops = DBIO::MSSQL::Diff::PrimaryKey->diff(
        $source_columns, $target_columns, $source_tables, $target_tables,
        \@column_ops);

=head2 as_sql

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
