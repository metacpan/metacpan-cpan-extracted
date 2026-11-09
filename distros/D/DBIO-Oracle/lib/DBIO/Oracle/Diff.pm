package DBIO::Oracle::Diff;
# ABSTRACT: Compare two introspected Oracle models

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Base';


use DBIO::Exception ();
use DBIO::Oracle::Diff::Table      ();
use DBIO::Oracle::Diff::Column     ();
use DBIO::Oracle::Diff::Index      ();
use DBIO::Oracle::Diff::ForeignKey ();
use DBIO::Oracle::Diff::Unique     ();
use DBIO::Oracle::Diff::View       ();

my %_REGISTRY = (
  tables  => 'DBIO::Oracle::Diff::Table',
  columns => 'DBIO::Oracle::Diff::Column',
  indexes => 'DBIO::Oracle::Diff::Index',
);

my @_ORDER = qw(tables columns indexes);

# The sections of the models a kind of operation is built from besides its own:
# which tables the models have, to tell a table both have from a new one.
my %_NEEDS_TABLES = map { $_ => 1 } qw(columns indexes);

sub _build_operations {
  my ($self) = @_;
  my (@ops, @gone_fk, @gone_unique, @new_unique, @new_fk);

  my ($src, $tgt) = ($self->source, $self->target);

  # Foreign keys and unique constraints (karr k64): the ones that are gone are
  # dropped before anything else happens to tables and columns, the new ones
  # are added after it.
  my @tables = ($src->{tables} // {}, $tgt->{tables} // {});
  my @fk = DBIO::Oracle::Diff::ForeignKey->diff(
    $src->{foreign_keys} // {}, $tgt->{foreign_keys} // {}, @tables, $tgt->{columns} // {},
  );
  my @uq = DBIO::Oracle::Diff::Unique->diff(
    $src->{unique_constraints} // {}, $tgt->{unique_constraints} // {}, @tables, $tgt->{columns} // {},
  );
  @gone_fk     = grep { $_->action eq 'drop' } @fk;
  @new_fk      = grep { $_->action eq 'create' } @fk;
  @gone_unique = grep { $_->action eq 'drop' } @uq;
  @new_unique  = grep { $_->action eq 'create' } @uq;

  # A key that stays over a unique constraint the target drops or changes
  # (ORA-02273, karr k64) goes first and is created again, unchanged, after.
  my ($again_drop, $again_new) = $self->_keys_over_gone_unique(\@gone_unique);
  push @gone_fk, @$again_drop;
  push @new_fk,  @$again_new;

  # Views (karr k65): the ones that are gone are dropped before the tables they
  # rest on are touched, the new and changed ones written after everything else.
  my @views = DBIO::Oracle::Diff::View->diff(
    @tables, $src->{views} // {}, $tgt->{views} // {},
  );
  my @gone_view = grep { $_->action eq 'drop' } @views;
  my @new_view  = grep { $_->action ne 'drop' } @views;

  push @ops, @gone_fk, @gone_unique, @gone_view;

  for my $key (@_ORDER) {
    my $diff_cls = $_REGISTRY{$key} or next;
    next unless exists $src->{$key} || exists $tgt->{$key};

    my @extra;
    if ($_NEEDS_TABLES{$key}) {
      @extra = @tables;
    }
    elsif ($key eq 'tables') {
      # what a table only the target has is created from
      @extra = (
        $tgt->{columns}            // {},
        $tgt->{unique_constraints} // {},
        $src->{columns}            // {},   # the sequences of a dropped table
      );
    }

    push @ops, $diff_cls->diff(
      $src->{$key} // {},
      $tgt->{$key} // {},
      @extra,
    );
  }

  push @ops, @new_unique, @new_fk, @new_view;

  # An index goes with a column it is on (ALTER TABLE ... DROP COLUMN): a
  # DROP INDEX after that fails with ORA-01418, so it is not written (karr k63).
  my %dropped;
  for my $op (@ops) {
    next unless $op->isa('DBIO::Oracle::Diff::Column') && $op->action eq 'drop';
    $dropped{ $op->table_name }{ $op->column_name } = 1;
  }
  if (%dropped) {
    @ops = grep {
      my $op = $_;
      !( $op->isa('DBIO::Oracle::Diff::Index') && $op->action eq 'drop'
         && $dropped{ $op->table_name }
         && grep { $dropped{ $op->table_name }{$_} } @{ ($op->index_info // {})->{columns} // [] } );
    } @ops;
  }

  return \@ops;
}

# The foreign keys that stay as they are over a unique constraint the diff
# drops (ORA-02273: Oracle will not drop a constraint a foreign key rests on).
# Returns the drops and the creates to put around the constraint operations;
# throws when the target has nothing for the key to point to.
sub _keys_over_gone_unique {
  my ($self, $gone) = @_;
  return ([], []) unless @$gone;
  my ($src, $tgt) = ($self->source, $self->target);

  my $set = sub { join ',', sort map { lc } @{ $_[0] // [] } };
  my %gone = map { ($_->table_name . "\x1f" . $set->($_->columns)) => 1 } @$gone;

  my (@drop, @new);
  for my $table (sort keys %{ $src->{foreign_keys} // {} }) {
    next unless exists( ($tgt->{tables} // {})->{$table} );
    my %want = map { DBIO::Oracle::Diff::ForeignKey::_signature($_) => $_ }
      @{ ($tgt->{foreign_keys} // {})->{$table} // [] };

    for my $fk (@{ $src->{foreign_keys}{$table} }) {
      my $stays = $want{ DBIO::Oracle::Diff::ForeignKey::_signature($fk) } or next;
      my $to    = $fk->{to_table};
      my $cols  = $set->($fk->{to_columns});
      next unless $gone{ $to . "\x1f" . $cols };

      my $held = grep { $set->($_->[1]) eq $cols } @{ ($tgt->{unique_constraints} // {})->{$to} // [] };
      $held ||= $set->(($tgt->{primary_keys} // {})->{$to}) eq $cols;
      unless ($held) {
        my @from = @{ $fk->{from_columns} // [] };
        my @to   = @{ $fk->{to_columns} // [] };
        DBIO::Exception->throw(sprintf
          "DBIO::Oracle::Diff: the foreign key '%s' of table '%s' (column%s %s) stays, "
          . "but it points to column%s %s of table '%s', over which the target model has "
          . 'no unique constraint and no primary key (Oracle refuses to drop the constraint '
          . 'under a foreign key, ORA-02273)',
          $stays->{constraint_name} // '', $table, (@from > 1 ? 's' : ''), join(', ', @from),
          (@to > 1 ? 's' : ''), join(', ', @to), $to);
      }

      push @drop, DBIO::Oracle::Diff::ForeignKey->new(
        action => 'drop', table_name => $table,
        constraint_name => $fk->{constraint_name}, fk_info => $fk,
      );
      push @new, DBIO::Oracle::Diff::ForeignKey->create_op($table, $stays);
    }
  }
  return (\@drop, \@new);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Diff - Compare two introspected Oracle models

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::Oracle::Diff> compares two introspected Oracle database models
(as produced by L<DBIO::Oracle::Introspect>) and produces a list of
structured diff operations. These operations can then be rendered to SQL
or a human-readable summary.

    my $diff = DBIO::Oracle::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

Diff operations are ordered: first the foreign keys that are gone, then the
unique constraints that are gone, then the views that are gone, then the
tables, the columns and the indexes, then the unique constraints that are new,
the foreign keys that are new, and the views that are new or changed last (a
foreign key to a new unique constraint needs it first, a key must be gone
before the table or column it points to, and a view rests on tables and
columns that must exist when it is written). Within the
tables, creates come before drops (a C<DROP TABLE> is therefore emitted before
any column or index operation).

A table that only the target model has is created whole, the way
L<DBIO::Oracle::DDL> writes the install: C<CREATE TABLE> with its columns,
primary key and unique constraints, then its sequence and trigger
(L<DBIO::Oracle::Diff::Table>); its indexes follow with the others
(L<DBIO::Oracle::Diff::Index>), and its foreign keys last, after every
C<CREATE TABLE> (L<DBIO::Oracle::Diff::ForeignKey>). Applied to a database
that holds the source model, the diff gives a database whose introspected
model compares equal to the target: a second diff is empty. A table that only
the source has is dropped (C<DROP TABLE ... CASCADE CONSTRAINTS>, then C<DROP
SEQUENCE> for the sequences the install made for it), and no
C<DROP INDEX> follows it: the indexes went with the table, and Oracle refuses
the statement (ORA-01418). A dropped column is dropped with C<CASCADE CONSTRAINTS> (a column of a
multi-column key cannot be dropped without it, ORA-12991), and the indexes on
a dropped column are not dropped by the diff: Oracle drops them with the column,
and a C<DROP INDEX> after it is ORA-01418. What the model does not
carry is not invented; see
L<DBIO::Oracle::Diff::Table/DESCRIPTION> for the trigger.

A table key C<schema.table> (what L<DBIO::Oracle::Introspect/schemas> gives for
a table of another schema) is written qualified by every operation:
C<"OWNX"."t">, with the index, sequence and trigger names in the same schema.
A foreign key's C<to_table> of that form is qualified likewise.

The foreign keys and the unique constraints of a table both models have are
compared and written: C<ALTER TABLE ... DROP CONSTRAINT> by the name
of the source model, C<ADD CONSTRAINT ... FOREIGN KEY> or C<UNIQUE> by the name
of the target model, and both for one that changed, the drop first (an action
is such a change). A foreign key is compared by its columns, the referenced
table and columns, C<on_delete>, C<on_update> and C<is_deferrable>, a unique
constraint by its columns; the names of the constraints do not count, and a
missing section counts as empty. A constraint over a column the target drops
goes with the column (C<CASCADE CONSTRAINTS>). Oracle has C<ON DELETE CASCADE>
and C<SET NULL> only: a foreign key with an C<ON UPDATE> action or C<SET
DEFAULT> is refused with a L<DBIO::Exception> naming the table and the column
(L<DBIO::Oracle::Diff::ForeignKey>, L<DBIO::Oracle::Diff::Unique>).
C<on_delete RESTRICT> is written as C<NO ACTION> (no clause), as
L<DBIO::Oracle::DDL> does, and is no difference from it.

Oracle refuses to drop a unique constraint a foreign key rests on (ORA-02273).
A foreign key that stays as it is over a unique constraint the target drops or
changes is therefore dropped first and created again, unchanged, after the
constraint: the key gone, the constraint gone, the constraint new, the key
new. If the target has neither a unique constraint nor the primary key over
the columns such a key points to, the diff refuses with a L<DBIO::Exception>
naming the table and the columns, before it returns a single operation.

The model carries the definition of a view (the C<views> section,
L<DBIO::Oracle::Introspect::Views>), and the diff writes C<CREATE OR REPLACE
VIEW> for a view that is new or whose definition changed and C<DROP VIEW> for
one that is gone. Definitions are compared after whitespace and a
trailing semicolon are normalized; what Oracle rewrites when it stores a view
is described in L<DBIO::Oracle::Diff::View/DESCRIPTION>.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::Oracle::Deploy> - install, and diff and upgrade against a temporary user

=item * L<DBIO::Oracle::Introspect> - produces the models being compared

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
