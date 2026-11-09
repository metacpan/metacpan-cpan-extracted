package DBIO::Firebird::Diff;
# ABSTRACT: Compare two introspected Firebird models

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Base';


use DBIO::Exception ();
use DBIO::Firebird::DDL qw(_firebird_quote_ident);
use DBIO::Firebird::Diff::Table ();
use DBIO::Firebird::Diff::Column ();
use DBIO::Firebird::Diff::Index ();
use DBIO::Firebird::Diff::Constraint ();
use DBIO::Firebird::Diff::View ();

sub _build_operations {
  my ($self) = @_;
  my @ops;

  # Views to drop go first, views to create last (a changed view is both; karr k61).
  my %views = DBIO::Firebird::Diff::View->diff(
    $self->source->{tables}, $self->target->{tables});
  push @ops, @{ $views{drops} };

  # The foreign keys, primary keys and unique constraints of the tables on
  # both sides and of the new ones (karr k34, k62), ordered below.
  my @constraints = DBIO::Firebird::Diff::Constraint->diff(
    $self->source->{unique_constraints}, $self->target->{unique_constraints},
    $self->source->{foreign_keys},       $self->target->{foreign_keys},
    $self->source->{tables},             $self->target->{tables},
    $self->source->{columns},            $self->target->{columns},
  );
  my $constraints = sub {
    my ($action, @kinds) = @_;
    return grep { my $o = $_; $o->action eq $action && grep { $o->kind eq $_ } @kinds } @constraints;
  };
  my @indexes = DBIO::Firebird::Diff::Index->diff(
    $self->source->{indexes}, $self->target->{indexes},
    $self->source->{tables},  $self->target->{tables},
  );

  # Foreign keys to drop come before the tables, so a table another one points
  # at can go.
  push @ops, $constraints->(drop => 'fk');
  push @ops, DBIO::Firebird::Diff::Table->diff(
    $self->source->{tables}, $self->target->{tables},
    $self->target->{columns}, $self->target->{foreign_keys},
    $self->source->{columns}, $self->source->{foreign_keys},
  );
  # Keys and indexes over a column go before the column does.
  push @ops, $constraints->(drop => qw(pk unique));
  push @ops, grep { $_->action eq 'drop' } @indexes;
  push @ops, DBIO::Firebird::Diff::Column->diff(
    $self->source->{columns}, $self->target->{columns},
    $self->source->{tables},  $self->target->{tables},
    $self->source->{unique_constraints}, $self->source->{foreign_keys},
  );
  push @ops, grep { $_->action ne 'drop' } @indexes;
  push @ops, $constraints->(create => qw(pk unique));
  push @ops, $constraints->(create => 'fk');

  push @ops, @{ $views{creates} };

  $self->_refuse_case_only_pairs(\@ops);

  return \@ops;
}


sub as_sql {
  my ($self) = @_;

  my @refused = grep { $_->isa('DBIO::Firebird::Diff::Column') && $_->refusal }
    @{ $self->operations };
  my @views = grep { $_->isa('DBIO::Firebird::Diff::Table') && $_->refusal }
    @{ $self->operations };

  DBIO::Exception->throw(join "\n",
    (@views       ? DBIO::Firebird::Diff::Table->refusal_error(@views) : ()),
    (@refused     ? DBIO::Firebird::Diff::Column->refusal_error(@refused) : ()),
  ) if @refused || @views;

  return $self->SUPER::as_sql;
}

# The names a list of operations drops and the names it creates, paired where
# they are equal but for letter case. One [ $kind, $source_name, $target_name,
# $table ] per pair, tables first, then columns, then indexes; $table is undef
# for a table.
#
# Read off the operations rather than the models: an operation is exactly what
# an unpaired name becomes, so what is found here is what would be rendered --
# and what the op classes leave out (the columns and indexes of a table that
# is created or dropped as a whole) is left out here too.
sub _case_only_pairs {
  my ($self, $ops) = @_;

  my @kinds = (
    [ table  => 'DBIO::Firebird::Diff::Table',  'table_name',  'create' ],
    [ column => 'DBIO::Firebird::Diff::Column', 'column_name', 'add'    ],
    [ index  => 'DBIO::Firebird::Diff::Index',  'index_name',  'create' ],
  );

  my @pairs;
  for my $kind (@kinds) {
    my ($word, $class, $name_of, $creates) = @$kind;

    # Columns and indexes are scoped by their table, tables by nothing.
    my (%gone, %new);
    for my $op (grep { $_->isa($class) } @$ops) {
      my $scope = $word eq 'table' ? '' : $op->table_name;
      if    ($op->action eq 'drop')   { $gone{$scope}{ $op->$name_of } = 1 }
      elsif ($op->action eq $creates) { $new{$scope}{ $op->$name_of }  = 1 }
    }

    for my $scope (sort keys %gone) {
      my %gone_left = %{ $gone{$scope} };
      my %new_left  = %{ $new{$scope} // {} };

      # A changed index is dropped and created under ONE name. That is one
      # object; it is on neither side of a pair.
      my @both = grep { $new_left{$_} } keys %gone_left;
      delete @gone_left{@both};
      delete @new_left{@both};

      for my $from (sort keys %gone_left) {
        push @pairs,
          map  { [ $word, $from, $_, ($word eq 'table' ? undef : $scope) ] }
          grep { lc $_ eq lc $from } sort keys %new_left;
      }
    }
  }

  return @pairs;
}

# Die instead of handing out operations that drop an object and create the
# same name in another case (karr k41). See NAMES THAT DIFFER ONLY IN CASE.
# Every way out the message names was run against Firebird 5.0.4, as were the
# two renames it says do not exist.
sub _refuse_case_only_pairs {
  my ($self, $ops) = @_;

  my @pairs = $self->_case_only_pairs($ops) or return;

  my (@found, %example);
  for my $pair (@pairs) {
    my ($kind, $from, $to, $table) = @$pair;
    $example{$kind} //= $pair;
    push @found, sprintf '  %s %s in the database, %s in the schema%s',
      $kind, _firebird_quote_ident($from), _firebird_quote_ident($to),
      defined $table ? sprintf(' (table %s)', _firebird_quote_ident($table)) : '';
  }

  my @advice;
  if (my $pair = $example{table}) {
    my ($from, $to) = map { _firebird_quote_ident($_) } @{$pair}[1, 2];
    push @advice,
      "  table:  declare it in the schema as it is stored -- table('$pair->[1]'), and its",
      '          columns in their stored spelling too. Nothing in the database',
      '          changes. Or move the data: Firebird cannot rename a table, so',
      "          create $to, copy the rows over from $from and drop $from.";
  }
  if (my $pair = $example{column}) {
    my ($from, $to, $table) = map { _firebird_quote_ident($_) } @{$pair}[1, 2, 3];
    push @advice,
      '  column: declare it in the schema as it is stored, or rename it:',
      "            ALTER TABLE $table ALTER COLUMN $from TO $to;",
      '          Firebird refuses that while a PRIMARY KEY, UNIQUE or FOREIGN KEY',
      '          constraint uses the column: drop the constraint, rename, add it',
      '          back.';
  }
  if (my $pair = $example{index}) {
    my ($from, $to) = map { _firebird_quote_ident($_) } @{$pair}[1, 2];
    push @advice,
      '  index:  Firebird cannot rename an index, and an index holds no data:',
      "            DROP INDEX $from;",
      "          The next diff creates $to.";
  }

  DBIO::Exception->throw(join "\n",
    sprintf(
      'refusing to diff: %d name%s in the database differ%s from the schema only in letter case',
      scalar @found, (@found == 1 ? ('', 's') : ('s', '')),
    ),
    '',
    @found,
    '',
    'Firebird folds an unquoted identifier to upper case, and DBIO::Firebird quotes',
    'every identifier it emits. An object that was created unquoted -- by an earlier',
    'DBIO::Firebird, or by hand -- is stored upper-cased and is not the object the',
    'schema names. To this diff the two spellings are two objects: it would drop the',
    'one in the database and create the one in the schema, and for a table or a',
    'column that destroys the data. No statement was generated.',
    '',
    'What you can do:',
    '',
    @advice,
    # throw() takes one newline off and appends where it was called from; the
    # second one keeps that off the last line of advice.
    '', '',
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Diff - Compare two introspected Firebird models

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::Firebird::Diff> compares two introspected Firebird database models
(as produced by L<DBIO::Firebird::Introspect>) and produces a list of
structured diff operations. These operations can then be rendered to SQL or a
human-readable summary.

    my $diff = DBIO::Firebird::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

Diff operations are generated in dependency order: views to drop, foreign keys
to drop, tables, primary keys and unique constraints to drop, indexes to drop,
columns, indexes to create, primary keys and unique constraints to add,
foreign keys to add, then the views to create or replace.

The target model's indexes come from L<DBIO::Firebird::DDL/install_ddl>, so
they include the canonical index declaration of the result source (C<idx>,
C<indices>); what that method refuses is refused here too.

=head1 METHODS

=head2 as_sql

The statements of all operations as one script -- or, if the diff holds a
column change the server refuses, a L<DBIO::Exception> that lists every such
column and renders nothing. See L</COLUMN CHANGES THE SERVER REFUSES>.

=head1 NAMES THAT DIFFER ONLY IN CASE

Names are compared exactly, the way Firebird compares quoted names: C<ARTIST>
and C<artist> are two tables. One situation makes that comparison destructive,
and the diff refuses it instead of rendering it.

Firebird folds an unquoted identifier to upper case, and this distribution
quotes every identifier it emits (L<DBIO::Firebird::DDL/install_ddl>). A
database whose objects were created unquoted -- by hand or with another
tool -- holds C<ARTIST> where the schema says
C<artist>. Compared exactly, that is one table to drop and one to create, and
applying it empties the table.

So when a name only the source model has and a name only the target model has
are equal but for letter case, building the operations dies with a
L<DBIO::Exception>. It lists every such pair of the whole diff, not just the
first. No operation is handed out and no statement rendered, the unrelated
ones included: L<has_changes|DBIO::Diff::Base/has_changes>,
L<as_sql|DBIO::Diff::Base/as_sql>, L<summary|DBIO::Diff::Base/summary> and
L<operations|DBIO::Diff::Base/operations> all die, and so do
L<DBIO::Deploy::Base/apply> and L<DBIO::Deploy::Base/upgrade>, before they send
anything. L<DBIO::Deploy::Base/diff> itself returns: it builds the two models
and this object, and the operations are computed on first use.

This is checked for the three kinds of object the diff has operations for:
tables, and the columns and indexes of a table both models have under one
name. The columns and indexes of a table that is itself such a pair are not
listed again. Only I<unpaired> names count: if the database has both C<ARTIST>
and C<artist> and the schema has C<artist>, then C<ARTIST> is a table the
schema does not have and is dropped like any other; if the schema has both and
the database has C<ARTIST>, then C<artist> is new.

There is no switch to diff anyway. The ways out, as Firebird 5.0 has them:

=over 4

=item Tables

Declare the table in the schema as the database stores it --
C<< __PACKAGE__->table('ARTIST') >>, and its columns in their stored spelling
too, they were folded the same way. Nothing in the database changes, and the
ORM, which quotes, then addresses the table that is there.

Or move the data. Firebird cannot rename a table: create C<"artist">, copy the
rows over from C<"ARTIST">, drop C<"ARTIST">. The two exist side by side in
between -- and while they do, C<ARTIST> is unpaired, so an C<upgrade> run
before the rows are copied drops it.

=item Columns

Declare the column in the schema as it is stored, or rename it:

    ALTER TABLE "cd" ALTER COLUMN "TITLE" TO "title";

Firebird refuses that while a C<PRIMARY KEY>, C<UNIQUE> or C<FOREIGN KEY>
constraint uses the column; drop the constraint, rename, add it back.

=item Indexes

Firebird cannot rename an index, and an index holds no data: C<DROP INDEX
"CD_TITLE_IDX">, and the next diff creates C<"cd_title_idx">.

This is the one a schema declaring the stored spelling still meets.
L<DBIO::Firebird::DDL/install_ddl> names the index of a unique column
C<< <table>_<column>_idx >>, with that lower-case suffix, so the old
C<ARTIST_NAME_IDX> stands against C<"ARTIST_NAME_idx">, and nothing declared in
the schema changes the suffix.

=back

The op classes do not check this themselves: their C<diff> class methods
(L<DBIO::Firebird::Diff::Table/diff> and its siblings) return the plain drop
and create operations when called directly.

=head1 COLUMN CHANGES THE SERVER REFUSES

Some column changes Firebird refuses outright: narrowing a C<VARCHAR>, a
character column into a numeric one, a digit count that shrinks, any type
change of a column a C<PRIMARY KEY>, C<UNIQUE> or C<FOREIGN KEY> constraint
uses. Sent, the statement fails on the server and leaves an
C<upgrade> half applied, and the same difference is back on the next run.

The diff therefore keeps reporting such a change -- C<has_changes> is true,
C<summary> and C<operations> list it -- but refuses to I<render> it:
C<as_sql> dies with a L<DBIO::Exception> naming every such column with table,
old and new type and the reason, and renders nothing, the unrefused statements
included. L<DBIO::Deploy::Base/apply> and L<DBIO::Deploy::Base/upgrade> render
the whole script before they execute the first statement, so they die before
they touch the database. The rules, as measured on the server, and what is
I<not> refused: L<DBIO::Firebird::Diff::Column/COLUMN CHANGES THE SERVER REFUSES>.

=head1 VIEWS

The introspected model lists a view in C<tables> (C<kind =E<gt> 'view'>) with
its definition, C<rdb$view_source>, as C<view_source>, and its columns in
C<columns>. The diff writes C<CREATE VIEW> for a view the
schema has and the database lacks, and C<DROP VIEW> for a view only the
database has; a view with another definition is dropped and created again
(L<DBIO::Firebird::Diff::View>). Definitions are compared after leading and
trailing whitespace is cut and every run of whitespace is one blank; any other
difference in the text is a change. The columns of a view are never altered
like a table's.

The order: the views to drop -- removed ones and changed ones -- come first,
then the tables, columns, indexes and constraints, then the views to create
(new ones and the changed ones again) -- so a view is gone before the table or
column it read is dropped (a changed view that no longer reads a column does
not stop that column from going) and exists after the tables and columns it
reads. Among views, one that reads another (its definition names it) is
dropped before and created after it.

The diff does not guess what the server accepts. When Firebird refuses a
statement (a view that other objects depend on, an I<unchanged> view that reads a
changed one -- it is not dropped with it --, a definition over a column that
is dropped in the same diff), the server's error is raised from
C<apply>/C<upgrade> as it is. A name that is a table on one side and a view on
the other is the exception: it is refused before any statement
(L<DBIO::Firebird::Diff::Table/refusal>).

=head1 PRIMARY KEYS, FOREIGN KEYS AND UNIQUE CONSTRAINTS

The target model is the temp database the schema was installed into, so it
holds the foreign keys and unique constraints L<DBIO::Firebird::DDL/install_ddl>
writes. A table that is new gets its constraints as
C<ALTER TABLE ... ADD CONSTRAINT> after all C<CREATE TABLE> statements of the
diff. A table that exists on both sides gets every difference in a constraint
-- its primary key too, compared by its columns in key order -- written as
C<DROP CONSTRAINT> and C<ADD CONSTRAINT>, a changed one as both.
The order is the one of L</DESCRIPTION>: foreign keys go first and come last,
so no key is dropped under a foreign key and none is added over a column that
is not there yet; an index is dropped before the column it covers. Check
constraints are not part of the model and not touched. See
L<DBIO::Firebird::Diff::Constraint>.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::Firebird::Deploy> - orchestrates introspection and diff

=item * L<DBIO::Firebird::Introspect> - produces the models being compared

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
