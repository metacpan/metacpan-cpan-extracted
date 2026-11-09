package DBIO::MSSQL::Diff;
# ABSTRACT: Compare two introspected MSSQL models

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Base';


use DBIO::Exception ();
use DBIO::MSSQL::Diff::Schema;
use DBIO::MSSQL::Diff::Table;
use DBIO::MSSQL::Diff::View;
use DBIO::MSSQL::Diff::Column;
use DBIO::MSSQL::Diff::Index;
use DBIO::MSSQL::Diff::ForeignKey;
use DBIO::MSSQL::Diff::PrimaryKey;
use DBIO::MSSQL::DDL qw(_check_cascade_paths _check_constraint_names _constraint_name);

sub _build_operations {
  my ($self) = @_;

  # names follow the collation of the live database (karr k77)
  my $target = $self->_fold_names($self->target);

  # a schema the target needs and the live database lacks (karr k72)
  my @schemas = DBIO::MSSQL::Diff::Schema->diff($self->source, $target);

  my @tables = DBIO::MSSQL::Diff::Table->diff(
    $self->source->{tables}, $target->{tables}, $target->{columns},
  );
  my @columns = DBIO::MSSQL::Diff::Column->diff(
    $self->source->{columns}, $target->{columns},
    $self->source->{tables},  $target->{tables},
  );
  my @views = DBIO::MSSQL::Diff::View->diff(
    $self->source->{tables}, $target->{tables},
  );
  my @indexes = DBIO::MSSQL::Diff::Index->diff(
    $self->source->{indexes}, $target->{indexes},
    $self->source->{tables},  $target->{tables},
  );
  my @fks = DBIO::MSSQL::Diff::ForeignKey->diff(
    $self->source->{foreign_keys}, $target->{foreign_keys},
    $self->source->{tables},       $target->{tables},
  );

  # The primary key of a table that exists on both sides (karr k74).
  my @pks = DBIO::MSSQL::Diff::PrimaryKey->diff(
    $self->source->{columns}, $target->{columns},
    $self->source->{tables},  $target->{tables}, \@columns,
  );

  # An ALTER COLUMN the server refuses while an index or unique constraint
  # covers the column: drop those in phase 2 and create them again in phase 6
  # (unless the diff drops or creates that very index anyway).
  {
    my %have = map { join("\0", $_->action, $_->table_name, $_->index_name) => 1 } @indexes;
    my $src = $self->source->{indexes} // {};
    my $tgt = $target->{indexes} // {};
    my (@extra_drop, @extra_create);
    for my $op (grep { $_->unbinds_dependents } @columns) {
      my ($t, $c) = ($op->table_name, $op->column_name);
      for my $name (sort keys %{ $src->{$t} // {} }) {
        my $i = $src->{$t}{$name};
        next unless grep { $_ eq $c } @{ $i->{columns} // [] };
        push @extra_drop, DBIO::MSSQL::Diff::Index->new(action => 'drop',
          table_name => $t, index_name => $name, index_info => $i)
          unless $have{join "\0", 'drop', $t, $name}++;
        my $n = $tgt->{$t}{$name};
        push @extra_create, DBIO::MSSQL::Diff::Index->new(action => 'create',
          table_name => $t, index_name => $name, index_info => $n)
          if $n && !$have{join "\0", 'create', $t, $name}++;
      }
    }
    push @indexes, @extra_drop, @extra_create;
  }

  # Foreign keys around a key or a column that changes. The server refuses to
  # drop a primary key or unique key a foreign key references, to ALTER COLUMN
  # to another type (a width change too) a column a foreign key stands on --
  # child or referenced column -- and cannot create a foreign key onto columns
  # no primary or unique key covers (all measured, karr k74). One rule: a
  # foreign key that references a key the diff drops (primary key, unique
  # constraint or unique index, wherever the drop comes from) or that stands on
  # a column the diff retypes is dropped in phase 1 and, if the classes still
  # declare it, added again in phase 7 -- as an operation of the foreign key
  # diff, once, whatever else the diff does with it.
  {
    my %have = map { join("\0", $_->action, $_->table_name, $_->constraint_name) => 1 } @fks;
    my $src = $self->source->{foreign_keys} // {};
    my $tgt = $target->{foreign_keys} // {};
    my $tgt_idx = $target->{indexes} // {};
    my $tgt_cols = $target->{columns} // {};
    my $set = sub { join "\0", sort @{ $_[0] // [] } };

    my $around = sub {
      my ($table, $fk) = @_;
      my $name = $fk->{constraint_name};
      push @fks, DBIO::MSSQL::Diff::ForeignKey->new(action => 'drop',
        table_name => $table, constraint_name => $name, fk_info => $fk)
        unless $have{join "\0", 'drop', $table, $name}++;
      my ($new) = grep { $_->{constraint_name} eq $name } @{ $tgt->{$table} // [] };
      push @fks, DBIO::MSSQL::Diff::ForeignKey->new(action => 'add',
        table_name => $table, constraint_name => $name, fk_info => $new)
        if $new && !$have{join "\0", 'add', $table, $name}++;
    };

    # the keys the diff drops: [ table, [ columns ] ]
    my @dropped = (
      (map { [ $_->table_name, $_->columns ] } grep { $_->action eq 'drop' } @pks),
      (map { [ $_->table_name, $_->index_info->{columns} // [] ] }
        grep { $_->action eq 'drop' && $_->index_info->{is_unique} } @indexes),
    );
    for my $key (@dropped) {
      my ($table, $cols) = @$key;
      my $want = $set->($cols);

      # a foreign key the classes declare onto columns that no key covers
      # afterwards could not be created: refuse before anything is dropped
      my $candidate =
        (grep { $_->{is_unique} && $set->($_->{columns}) eq $want }
           values %{ $tgt_idx->{$table} // {} })
        || ($set->([ map { $_->{column_name} } grep { $_->{is_pk} }
                       @{ $tgt_cols->{$table} // [] } ]) eq $want);
      unless ($candidate) {
        for my $t (sort keys %$tgt) {
          for my $fk (@{ $tgt->{$t} }) {
            next unless $fk->{to_table} eq $table && $set->($fk->{to_columns}) eq $want;
            DBIO::Exception->throw(sprintf
              "DBIO::MSSQL: the key of table '%s' (%s) cannot be dropped: "
              . "the classes declare no primary key or unique key over these columns, "
              . "but declare the foreign key '%s' of table '%s' that references them and "
              . "would have nothing to reference (no primary or candidate key). Declare "
              . "the primary key, or a unique constraint over the same columns, or drop "
              . "the foreign key",
              $table, join(', ', @$cols), $fk->{constraint_name}, $t);
          }
        }
      }

      for my $t (sort keys %$src) {
        for my $fk (@{ $src->{$t} }) {
          $around->($t, $fk) if $fk->{to_table} eq $table && $set->($fk->{to_columns}) eq $want;
        }
      }
    }

    for my $op (grep { $_->retypes } @columns) {
      my ($table, $col) = ($op->table_name, $op->column_name);
      for my $t (sort keys %$src) {
        for my $fk (@{ $src->{$t} }) {
          $around->($t, $fk)
            if ($t eq $table && grep { $_ eq $col } @{ $fk->{from_columns} // [] })
            || ($fk->{to_table} eq $table && grep { $_ eq $col } @{ $fk->{to_columns} // [] });
        }
      }
    }
  }

  # The keys the target will hold are checked as install_ddl checks the ones
  # of the classes: the server refuses cascading cycles and multiple cascade
  # paths (Msg 1785) when a key is added. Only when one is added, and on the
  # target model, which has every table; the source is what the server holds.
  if (grep { $_->action eq 'add' } @fks) {
    my $by_table = $target->{foreign_keys} // {};
    _check_cascade_paths([
      map {
        my $table = $_;
        map {
          +{
            table     => $table,
            label     => "constraint '$_->{constraint_name}'",
            from_cols => $_->{from_columns},
            to_table  => $_->{to_table},
            to_cols   => $_->{to_columns},
            on_delete => $_->{on_delete} || 'NO ACTION',
            on_update => $_->{on_update} || 'NO ACTION',
          }
        } @{ $by_table->{$table} };
      } sort keys %$by_table
    ]);
  }

  # Constraint and object names share one namespace (Msg 2714): the target
  # model is judged as install_ddl judges the classes.
  {
    my %objects = map { $_ => 1 } keys %{ $target->{tables} // {} };
    my @constraints;
    my $fks = $target->{foreign_keys} // {};
    for my $table (sort keys %$fks) {
      push @constraints, map { +{
        table   => $table, name => $_->{constraint_name} // '',
        label   => 'foreign key', columns => $_->{from_columns},
      } } @{ $fks->{$table} };
    }
    my $idx = $target->{indexes} // {};
    for my $table (sort keys %$idx) {
      for my $name (sort keys %{ $idx->{$table} }) {
        my $i = $idx->{$table}{$name};
        next unless $i->{is_unique_constraint};
        push @constraints, { table => $table, name => $i->{index_name} // $name,
          label => 'unique constraint', columns => $i->{columns} };
      }
    }
    # the primary keys the diff writes: those of new tables and the added ones
    my %new_table = map { $_->table_name => 1 } grep { $_->action eq 'create' } @tables;
    my %add_pk    = map { $_->table_name => 1 } grep { $_->action eq 'create' } @pks;
    my $cols = $target->{columns} // {};
    for my $table (sort keys %new_table, sort keys %add_pk) {
      my @pk = grep { $_->{is_pk} } @{ $cols->{$table} // [] };
      push @constraints, { table => $table, name => _constraint_name('PK', $table),
        label => 'primary key', columns => [ map { $_->{column_name} } @pk ] }
        if @pk;
    }
    _check_constraint_names(\%objects, \@constraints);
  }

  my $drop = sub { $_->action eq 'drop' };
  return [
    @schemas,
    (grep { $drop->() } @fks),
    (grep { $drop->() } @views),
    (grep { $drop->() } @indexes),
    (grep { $drop->() } @pks),
    (grep { $drop->() } @tables),
    @columns,
    (grep { !$drop->() } @tables),
    (grep { !$drop->() } @pks),
    (grep { !$drop->() } @indexes),
    (grep { !$drop->() } @fks),
    (grep { !$drop->() } @views),
  ];
}


sub _fold_names {
  my ($self, $target) = @_;
  my $source = $self->source;
  my $coll = $source->{collation};
  return $target unless $coll && !$coll->{case_sensitive};

  # a function from a name to the live spelling of the same name (or itself)
  my $map = sub {
    my %by = map { lc($_) => $_ } @_;
    return sub { defined $_[0] ? ($by{ lc $_[0] } // $_[0]) : undef };
  };
  my $table_of = $map->(keys %{ $source->{tables} // {} }, keys %{ $source->{columns} // {} });

  # the live column spelling of the table the target calls $tname
  my $col_of = sub {
    my ($tname) = @_;
    my $live = $table_of->($tname);
    return $map->(map { $_->{column_name} } @{ $source->{columns}{$live} // [] });
  };
  my $cols = sub { my ($f, $list) = @_; [ map { $f->($_) } @{ $list // [] } ] };

  my (%tables, %columns, %indexes, %fks);
  for my $t (keys %{ $target->{tables} // {} }) {
    $tables{ $table_of->($t) } = { %{ $target->{tables}{$t} }, table_name => $table_of->($t) };
  }
  for my $t (keys %{ $target->{columns} // {} }) {
    my $f = $col_of->($t);
    $columns{ $table_of->($t) } = [ map { +{ %$_, column_name => $f->($_->{column_name}) } }
      @{ $target->{columns}{$t} } ];
  }
  for my $t (keys %{ $target->{indexes} // {} }) {
    my $live  = $table_of->($t);
    my $f     = $col_of->($t);
    my $iname = $map->(keys %{ $source->{indexes}{$live} // {} });
    for my $n (keys %{ $target->{indexes}{$t} }) {
      my $i = $target->{indexes}{$t}{$n};
      $indexes{$live}{ $iname->($n) } = { %$i,
        (exists $i->{index_name} ? (index_name => $iname->($i->{index_name})) : ()),
        columns => $cols->($f, $i->{columns}) };
    }
  }
  for my $t (keys %{ $target->{foreign_keys} // {} }) {
    my $live  = $table_of->($t);
    my $f     = $col_of->($t);
    my $cname = $map->(map { $_->{constraint_name} } @{ $source->{foreign_keys}{$live} // [] });
    push @{ $fks{$live} }, map {
      +{ %$_,
         constraint_name => $cname->($_->{constraint_name}),
         from_columns    => $cols->($f, $_->{from_columns}),
         to_table        => $table_of->($_->{to_table}),
         to_columns      => $cols->($col_of->($_->{to_table}), $_->{to_columns}) }
    } @{ $target->{foreign_keys}{$t} };
  }

  return { %$target,
    tables => \%tables, columns => \%columns, indexes => \%indexes, foreign_keys => \%fks };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Diff - Compare two introspected MSSQL models

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::MSSQL::Diff> compares two introspected MSSQL models (produced
by L<DBIO::MSSQL::Introspect>) and emits a list of structured diff
operations that can be rendered to SQL or a human-readable summary.

    my $diff = DBIO::MSSQL::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

Operations are emitted in an order the server accepts, not in the order the
sub-diffs find them (the core walk sorts tables alphabetically, which is no
dependency order). Foreign keys make the order matter, so the operations come
in seven phases, after the C<CREATE SCHEMA> operations of
L<DBIO::MSSQL::Diff::Schema> (a schema that a table C<schema.table> of the
classes needs and the database lacks) that come first (the primary keys of
L<DBIO::MSSQL::Diff::PrimaryKey> take part in two of them):

=over

=item 1. every C<DROP CONSTRAINT> of a foreign key -- also those of a dropped
table, so tables that reference each other can be dropped (Msg 3726), and
before a column they use is dropped or altered (Msg 5074). The same phase
also takes the foreign keys that stand on a column the diff retypes (child or
referenced column, a width change included: the server refuses C<ALTER COLUMN>
while the key stands) and those that reference a key the diff drops, one rule
for primary keys and unique keys alike; they are added again in phase 7 if
the classes still declare them. The diff refuses when a declared foreign key
would reference columns that no primary or unique key covers once the key is
dropped;

=item 2. drops of indexes and unique constraints (before the columns they
cover), then the drop of a primary key that differs from the one of the classes
(a key the classes do not declare at all is dropped without being added), and
the same is done around an C<ALTER COLUMN> to another type on a key column;

=item 3. C<DROP TABLE>;

=item 4. column operations -- an C<ALTER COLUMN> that the server refuses while
an index or unique constraint covers the column (NULL to NOT NULL, a type
change; measured, see L<DBIO::MSSQL::Diff::Column/DEPENDENT INDEXES AND UNIQUE
CONSTRAINTS>) gets the drop of those indexes and constraints in phase 2 and
their creation again in phase 6, unless the diff drops or creates them anyway;

=item 5. C<CREATE TABLE>, without foreign keys (Msg 1767: a table can only be
referenced once it exists, and two tables can reference each other);

=item 6. C<ADD CONSTRAINT ... PRIMARY KEY> for a table that exists (a column
that becomes part of the key is C<NOT NULL> by then, which the server demands),
then creation of indexes and unique constraints (on new tables as well,
and before a foreign key that references a unique constraint);

=item 7. every C<ADD CONSTRAINT> of a foreign key, new tables included.

=back

B<Views> are L<DBIO::MSSQL::Diff::View> operations. The introspected model
lists them in C<tables> with C<< kind => 'view' >> and their stored text in
C<definition>. A view the classes declare and the database lacks, or holds
with another body (the text after C<AS>, white space folded), is written
C<CREATE OR ALTER VIEW> after everything else (after the foreign keys: the
tables, columns and keys it reads exist by then); a live view the classes do
not declare is dropped with C<DROP VIEW> right after the foreign key drops,
before the tables go. Each statement is a batch of its own. A view gets no
table, column or index operation (a C<CREATE TABLE> under a view's name would
block the view for good). Views that read other views are ordered by what they
read (C<depends_on> in the model, from C<sys.sql_expression_dependencies>):
written after the views they read, dropped before them; a cycle or an unknown
view read is refused.

=head1 METHODS

=head2 _fold_names

    my $target = $diff->_fold_names($diff->target);

When the source model says its database ignores case (C<collation> with
C<case_sensitive> false, set by L<DBIO::MSSQL::Introspect>), C<Foo> and C<foo>
are one name to the server, and the diff must not see a table, column, index
or foreign key as dropped and created for a change of spelling. This
returns the target model with every name that matches a live name ignoring
case written in the live spelling: table names, column names (also in index
and foreign key column lists), index and constraint names, the table a foreign
key references. Names the live side has no match for keep the spelling of the
classes. A case-sensitive source, or one that names no collation, gives the
target back unchanged: exact comparison, as before. The models handed in are
not modified.

The database that is migrated decides, not the temporary one the target is
introspected from (which is created with the collation of the live database,
see L<DBIO::MSSQL::Deploy/_create_temp_db>). A change of spelling alone is
B<not> carried out as a C<sp_rename>: the server would accept it (measured),
but the diff has never renamed anything, and an empty second diff is the goal.

=head1 SEE ALSO

=pod

=over

=item * L<DBIO::MSSQL::Introspect> - produces the models this class compares

=item * L<DBIO::MSSQL::Deploy> - uses this class for upgrade diffs

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
