package DBIO::Sybase::Diff::Column;
# ABSTRACT: Diff Sybase ASE columns

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp ();
use DBIO::Exception ();

use DBIO::Diff::Compare qw(changed_column_fields);
use DBIO::Sybase::DDL ();
use DBIO::Sybase::Quote ();


sub diff {
  my ($class, $source, $target, $source_tables, $target_tables) = @_;
  $source_tables  //= {};
  $target_tables  //= {};
  my @ops;

  for my $table (sort keys %$target) {
    # A table this diff is CREATING already carries every one of its columns in
    # the CREATE TABLE that DBIO::Sybase::Diff::Table emits (it is handed
    # $target->{columns} for exactly that). Adding them again here produced a
    # migration that created the column and then added it a second time --
    # "CREATE TABLE fresh (id INT NOT NULL); ALTER TABLE fresh ADD id INT" --
    # which ASE rejects as a duplicate column name. The two table models were
    # already being passed in for this guard and were accepted and ignored.
    #
    # The condition mirrors Diff::Table's own ("create when the table is not in
    # the source"), but is stated positively -- absent from source AND present
    # in target -- so that a caller supplying no table model at all (the
    # column-level unit tests pass {}, {}) knows nothing to be new and keeps
    # diffing every table, rather than silently skipping all of them.
    next if !exists $source_tables->{$table} && exists $target_tables->{$table};

    # The columns of a view are what its query selects: a changed view is
    # dropped and created again by DBIO::Sybase::Diff::View, ALTER TABLE on
    # a view is Msg 4909 (karr k98).
    next if ($source_tables->{$table}{kind} // '') eq 'view'
      || ($target_tables->{$table}{kind} // '') eq 'view';

    my $s_cols = $source->{$table} // [];
    my $t_cols = $target->{$table} // [];

    my %s_idx = map { $_->{column_name} => $_ } @$s_cols;
    my %t_idx = map { $_->{column_name} => $_ } @$t_cols;

    for my $name (sort keys %t_idx) {
      if (exists $s_idx{$name}) {
        push @ops, DBIO::Sybase::Diff::Column::Alter->new(
          action => 'alter',
          table  => $table,
          from   => $s_idx{$name},
          to     => $t_idx{$name},
        ) if changed_column_fields(
          _comparable($s_idx{$name}), _comparable($t_idx{$name}));
      }
      else {
        push @ops, DBIO::Sybase::Diff::Column::Add->new(
          action => 'add',
          table  => $table,
          col    => $t_idx{$name},
        );
      }
    }

    for my $name (sort keys %s_idx) {
      push @ops, DBIO::Sybase::Diff::Column::Drop->new(
        action => 'drop',
        table  => $table,
        col    => $s_idx{$name},
      ) unless exists $t_idx{$name};
    }
  }

  return @ops;
}

# A column as the comparator should see it. An expression default is a SCALAR
# ref (DBIO::Sybase::Introspect::Columns reads `DEFAULT getdate()` that way),
# and core compares default_value as a string -- a ref's string is its
# address, so the live and the desired getdate() would differ on every diff.
# Compare the SQL behind the ref instead, marked so it never equals the plain
# literal of the same text (karr k48).
#
# One expression is not an expression at all: a bare number on a numeric
# column. \'0' and the literal 0 render the same DEFAULT 0 there (karr k55), and
# the catalog reads that text back as the literal, so the ref compares as the
# literal it is equivalent to.
sub _comparable {
  my ($col) = @_;
  my $dv = $col->{default_value};
  return $col unless ref $dv eq 'SCALAR';
  return { %$col, default_value => $$dv }
    if DBIO::Sybase::DDL::_is_numeric_type($col->{data_type})
    && DBIO::Sybase::DDL::_is_numeric_literal($$dv);
  return { %$col, default_value => "\0sql:$$dv" };
}

package DBIO::Sybase::Diff::Column::Add;
use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(table col));

sub as_sql {
  my $self = shift;
  my $col  = $self->col;
  my $name = $col->{column_name};

  my $type = DBIO::Sybase::DDL::sybase_column_type(
    $col->{data_type}, $col->{size});

  # Clause order is the grammar's, not Transact-SQL's: ASE puts the default
  # BEFORE the nullability -- see L</THE ADD CLAUSE ORDER IS DEFAULT, THEN
  # NULLABILITY>. sybase_default_clause carries its own leading space and
  # renders '' for both an absent default and the literal 'null'.
  my $default = DBIO::Sybase::DDL::sybase_default_clause(
    $col->{default_value}, $col->{data_type}, $name);

  # A not-null add without a default is not a statement ASE will run, so it is
  # refused here rather than sent -- see L</A NOT NULL ADD CARRIES ITS
  # DEFAULT>. The test is the RENDERED clause, not $col->{default_value}: a
  # default_value of 'null' renders nothing, which leaves exactly the statement
  # the server rejects, and a contradiction ("no nulls, default null") worth
  # naming rather than passing on.
  DBIO::Exception->throw(sprintf(
    'DBIO::Sybase: table %s, column %s: cannot ALTER TABLE %s ADD %s -- the add '
      . 'is refused: ASE requires a default '
      . 'clause on a not-null add (Reference Manual: Commands, alter table: '
      . '"If you specify (or imply) not null for the newly added column, a '
      . 'default clause is required") and the desired column names no usable '
      . 'default_value',
    $self->table, $name, $self->table, $name,
  )) if $col->{not_null} && !length $default;

  # ... and the default of a not-null add is a constant: a function such as
  # getdate() is Msg 13918 ("Default cannot be an expression when adding
  # non-NULL column"), after which Msg 11050 aborts the statement (karr k97).
  DBIO::Exception->throw(sprintf(
    'DBIO::Sybase: table %s, column %s: ALTER TABLE ADD of a NOT NULL column '
      . 'with an expression default is refused: ASE cannot add a NOT NULL column '
      . 'with an expression default (Msg 13918). Give the column a constant '
      . 'default, or add it as nullable',
    $self->table, $name,
  )) if $col->{not_null} && ref $col->{default_value} eq 'SCALAR';

  # Always spelled out, never omitted -- an add that says nothing is not
  # neutral, it inherits the database's null default (see L</NULLABILITY IS
  # ALWAYS SPELLED OUT>). Read straight from the target: an add has no live
  # column to fall back to, and this is the same truthiness
  # DBIO::Sybase::Diff::Table::Create reads the field with.
  sprintf 'ALTER TABLE %s ADD %s %s%s %s;',
    DBIO::Sybase::Quote::quote_ident($self->table),
    DBIO::Sybase::Quote::quote_ident($name), $type, $default,
    ($col->{not_null} ? 'NOT NULL' : 'NULL');
}
sub summary {
  my $self = shift;
  "ALTER TABLE $self->{table} ADD $self->{col}{column_name}";
}

package DBIO::Sybase::Diff::Column::Alter;
use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(table from to));

sub as_sql {
  my $self = shift;
  my $tbl      = DBIO::Sybase::Quote::quote_ident($self->table);
  my $from     = $self->from // {};
  my $to       = $self->to;
  my $col_name = $to->{column_name};

  # The desired state of one field, read the way the comparator that decided
  # this op exists reads it: a field the target leaves undef was not
  # prescribed, so the live value stands (DBIO::Diff::Compare's desired-state
  # skip, see L</THE DESIRED-STATE CONTRACT APPLIES TO RENDERING TOO>). Per
  # FIELD, not per hashref -- a target naming a type but no size keeps the
  # live width, because a bare VARCHAR in an ASE column definition is not
  # "unbounded" (karr k35).
  my $want = sub {
    my ($field) = @_;
    return defined $to->{$field} ? $to->{$field} : $from->{$field};
  };

  my $replace = $self->_replace_sql;

  # A default-only change is the replace and nothing else (karr k42): the
  # modify would restate a type, width and nullability the comparator found
  # unmoved, at the price of a data copy, and live on ASE 16.0 a replace takes
  # effect without one -- see L</A DEFAULT-ONLY CHANGE IS THE REPLACE ALONE>.
  return $replace if $self->_default_only;

  my $type = DBIO::Sybase::DDL::sybase_column_type(
    $want->('data_type'), $want->('size'));
  # MODIFY, not ALTER COLUMN: the latter is Transact-SQL and parses on no ASE
  # (karr k38). Nothing stands between the table name and the keyword -- see
  # L</THE ALTER IS A MODIFY, THE DEFAULT IS A SEPARATE REPLACE>.
  my $sql = sprintf 'ALTER TABLE %s MODIFY %s %s', $tbl,
    DBIO::Sybase::Quote::quote_ident($col_name), $type;
  # Stated on every alter, never omitted -- see L</NULLABILITY IS ALWAYS
  # SPELLED OUT>. Omitting it does not preserve the column's nullability.
  $sql .= $want->('not_null') ? ' NOT NULL;' : ' NULL;';

  # The default is NOT a clause of `modify`; it is its own subclause, and one
  # that cannot share a statement with the modify anyway (the manual allows
  # several subclauses per statement only for add/drop/modify/lock, and only
  # while no column is named twice). So it renders as a second statement,
  # separated by ';' -- what DBIO::Deploy::Base::_execute_ddl splits on, and
  # the same shape Diff::Index::Alter emits for its DROP/CREATE pair.
  $sql .= " $replace" if length $replace;

  $sql;
}

# The replace statement, or '' when there is nothing to replace.
#
# Emitted only on an actual change, and read from the target only, never
# through the desired-state fallback. Restating an unchanged default is not a
# harmless no-op here: on a column carrying an sp_bindefault-bound default ASE
# rejects the statement outright. An absent target default prescribes nothing
# (core's comparator never reports a dropped default), and the compared value
# is the RENDERED clause, so the literal 'null' -- which renders as nothing --
# emits nothing, and two expression defaults compare by their SQL rather than
# by the address of their SCALAR refs.
sub _replace_sql {
  my $self = shift;
  my $from = $self->from // {};
  my $to   = $self->to;
  # Each side renders under its OWN type (karr k55): a varchar column whose
  # default '0' is retyped to int keeps its default_value, but its live clause
  # DEFAULT '0' is the VARCHAR constant an INT column cannot insert, so the
  # replace must follow the modify. The target's type falls back to the live
  # one exactly as the modify reads it -- an unprescribed type did not move.
  my $want_type = defined $to->{data_type} ? $to->{data_type} : $from->{data_type};
  my $want_default = DBIO::Sybase::DDL::sybase_default_clause(
    $to->{default_value}, $want_type, $to->{column_name});
  my $live_default = DBIO::Sybase::DDL::sybase_default_clause(
    $from->{default_value}, $from->{data_type}, $to->{column_name});
  # A default the target no longer declares is removed, not kept (karr k97,
  # core karr k367: the comparator reports it, and the live DEFAULT NULL counts
  # as none). The Reference Manual's own example is
  # `alter table authors replace phone default null`.
  $want_default = ' DEFAULT NULL'
    if !length $want_default && length $live_default;
  return '' unless length $want_default && $want_default ne $live_default;
  return sprintf 'ALTER TABLE %s REPLACE %s%s;',
    DBIO::Sybase::Quote::quote_ident($self->table),
    DBIO::Sybase::Quote::quote_ident($to->{column_name}), $want_default;
}

# True when the replace is the whole statement: the comparator reports nothing
# but default_value as changed (the same exported call diff() makes, not a
# re-implementation of it -- a set test, since the list comes in spec-group
# order) AND there is a replace to emit. Without the second condition a
# default-only change that renders no replace -- the literal 'null' -- would
# leave an op with no SQL at all; it falls back to the modify it has always
# rendered instead.
sub _default_only {
  my $self = shift;
  my @moved = grep { $_ ne 'default_value' }
    DBIO::Diff::Compare::changed_column_fields($self->from // {}, $self->to);
  return !@moved && length $self->_replace_sql;
}


my %LOSSLESS_PAIRS = map { ($_ => 1) } (
  'tinyint->smallint', 'tinyint->int', 'tinyint->bigint',
  'smallint->int', 'smallint->bigint', 'int->bigint',
);

sub lossy {
  my ($self) = @_;
  return 0 unless $self->action eq 'alter';
  my ($old, $new) = ($self->from // {}, $self->to);
  return DBIO::Diff::Compare::column_change_lossy(
    { data_type => $old->{data_type}, size => $old->{size} },
    { data_type => $new->{data_type}, size => $new->{size} },
    \%LOSSLESS_PAIRS,
  ) ? 1 : 0;
}

sub summary {
  my $self = shift;
  # Names the clause the statement leads with, as the Add and Drop summaries
  # in this file do: REPLACE for a default-only change (karr k42), MODIFY
  # otherwise. A default change beside a modify adds a second statement that
  # the summary does not spell out -- Diff::Index::Alter's one-line summary
  # covers its DROP/CREATE pair the same way.
  my $keyword = $self->_default_only ? 'REPLACE' : 'MODIFY';
  "ALTER TABLE $self->{table} $keyword $self->{to}{column_name}";
}

package DBIO::Sybase::Diff::Column::Drop;
use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(table col));

sub as_sql {
  my $self = shift;
  # DROP, not DROP COLUMN: the drop subclause keywords only its constraint
  # arm, and names a column bare -- see L</THE DROP NAMES THE COLUMN AND
  # NOTHING ELSE>. This is what summary has always said (karr k41).
  sprintf 'ALTER TABLE %s DROP %s;',
    DBIO::Sybase::Quote::quote_ident($self->table),
    DBIO::Sybase::Quote::quote_ident($self->col->{column_name});
}
sub summary {
  my $self = shift;
  "ALTER TABLE $self->{table} DROP $self->{col}{column_name}";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Diff::Column - Diff Sybase ASE columns

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Compares two column sets and generates column-level diff operations.

=head1 METHODS

=head2 lossy

    my $bool = $op->lossy;

True for the C<alter> of a column whose type change can lose or alter stored
values (optional operation method, ADR 0080): L<DBIO::Deploy::Base/apply> runs
such a diff with C<< allow_destructive => 1 >> only. The answer is
L<DBIO::Diff::Compare/column_change_lossy> over C<data_type> and C<size> of the
two columns, whose type names are the C<systypes> names
L<DBIO::Sybase::Introspect::Columns> reads (C<int>, C<smallint>, C<tinyint>,
C<bigint>). A change keeps every value when the type stays and the size does
not get smaller (the scale of a C<numeric> equal), or when it is one of the
integer widenings: C<tinyint> to C<smallint>, C<int> or C<bigint>, C<smallint>
to C<int> or C<bigint>, C<int> to C<bigint>. Every other type change is lossy,
the C<unsigned> types included. A change of nullability or default alone is
not (C<NOT NULL> over a C<NULL> is refused by
L<DBIO::Sybase::Deploy/_check_before_apply>), and neither is an added column.

=head1 A COLUMN IS RENDERED, NOT NAMED

C<add> and C<alter> emit the B<rendered> type from
L<DBIO::Sybase::DDL/sybase_column_type> -- the same function
L<DBIO::Sybase::Diff::Table> and C<install_ddl> use -- never the bare
C<data_type> string. The two sides of test-deploy-and-compare have to agree on
type rendering or the diff never converges: a column that C<CREATE TABLE>
deploys as C<VARCHAR(64)> but an incremental C<ADD> spells C<varchar> is
C<VARCHAR(255)> on the server, so the next introspection reports the size
back as changed and the diff reproduces itself forever.

The size is carried in its own model field (C<size>), not inside C<data_type>,
because that is the shape L<DBIO::Sybase::Introspect::Columns> produces --
C<syscolumns.length> / C<prec> / C<scale> alongside the type name. Dropping it
here is therefore not a cosmetic difference between two spellings of one type;
it is a column of the wrong width.

=head1 NULLABILITY IS ALWAYS SPELLED OUT

Both an C<add> and an C<alter> write an explicit C<NULL> or C<NOT NULL> on
every statement, even when nothing about the nullability moved. Omitting it
does B<not> leave the nullability to the column, so "say nothing and the
sensible thing happens" is not available in this dialect.

For an C<add> the manual says so in one sentence -- "If you do not specify
null or not null, the SAP ASE server uses not null by default. However, you
can switch this default using sp_dboption to make the default compatible with
the SQL standards" (Reference Manual: Commands, C<alter table>, parameter
C<null | not null>). A bare add therefore lands as C<NOT NULL> or C<NULL>
depending on a database option this driver cannot see, and a column the schema
declared nullable is created either way round. It is worse than a coin toss,
because the same DDL produces different columns on two servers.

For an C<alter> the same conclusion needs three facts from the C<modify>
production:

=over 4

=item *

The nullability is optional in the production --
C<< modify I<column_name> [ I<datatype> [null | not null] ] >> -- so a statement
without it parses, and there is no error to warn anybody.

=item *

What it falls back to is not the column's own state but a B<default>: for a
user-defined datatype the Transact-SQL User's Guide states it outright ("If you
do not specify either NULL or NOT NULL as the default, columns use the default
specified by the user-defined datatype"), and for a system datatype the
corresponding default is the database's, which is C<not null> unless
C<sp_dboption ... 'allow nulls by default'> has been turned on. Nothing in that
chain consults the existing column.

=item *

That default is therefore B<server configuration this driver cannot see>. Which
way a bare modify would land is a property of the target database, not of the
schema being deployed -- which makes omitting the nullability worse than
Transact-SQL's fixed "if not specified, the column is nullable": at least that
one is deterministic.

=back

Restating an unchanged nullability is consequently not redundancy, it is the
only spelling under which a type change keeps the column it found.

=head1 A NEW TABLE'S COLUMNS ARE NOT ADDED TWICE

C<diff> skips a table that is being B<created> by this same diff. Its columns
are already in the C<CREATE TABLE> L<DBIO::Sybase::Diff::Table> emits, so
adding them again produced a migration that created a column and then added
it a second time -- C<< CREATE TABLE fresh (id INT NOT NULL); ALTER TABLE
fresh ADD id INT >> -- which ASE rejects as a duplicate column name. Both
table models were already being passed to C<diff> for this guard; they were
accepted and never read.

The guard asks whether the table is B<known new> -- absent from the source
tables I<and> present in the target tables -- rather than merely absent from
the source. A caller that supplies no table model at all knows nothing to be
new and so skips nothing, which keeps column-level diffing usable on its own.

=head1 THE ADD CLAUSE ORDER IS DEFAULT, THEN NULLABILITY

The C<add> production puts the default B<before> the nullability, which is the
reverse of the Transact-SQL order a reader coming from L<DBIO::MSSQL> will
expect. Verbatim from the Reference Manual: Commands, C<alter table>:

    alter table [[database.][owner].]table_name
      {add column_name datatype}
      [default {constant_expression | user | null}]
      {identity | null | not null [not materialized]}

So this class emits

    ALTER TABLE t ADD extra VARCHAR(64) DEFAULT 'x' NOT NULL

and never C<... NOT NULL DEFAULT 'x'>. The C<create table> production orders
its column definition the same way, so the order is the dialect's rather than
a property of C<alter>.

=head1 A NOT NULL ADD CARRIES ITS DEFAULT

A not-null C<add> whose column names no default is B<refused> -- C<as_sql>
C<croak>s naming the table and column -- rather than rendered and sent. The
manual makes the default mandatory in that case, unconditionally and not only
for a populated table: "If you specify (or imply) not null for the newly added
column, a default clause is required. The default value is used for all
existing rows of the newly added column, and applies to future inserts as
well." The Usage section repeats it and admits exactly one exception: "If you
add a not null column, you must also specify a default clause. This rule has
one exception: if you add a user-defined type column, and the type has a
default bound to it, you need not specify a default clause."

Refusing is the house answer for a statement that cannot be made correct from
what the model carries -- L<DBIO::MSSQL::Diff::Column> C<croak>s the same way
on a default drop with no C<default_constraint_name>. The alternative is to
emit the statement anyway and let the server reject it, which trades a message
naming the schema column for an ASE error naming neither.

The one documented exception is out of reach on purpose. Whether a bound
default exists is a property of the B<server>, readable only by querying the
type's bindings, and the model this class renders from carries no such field;
guessing that a passthrough type name is a user-defined type with a default
bound to it would turn a loud refusal into a silent gamble. Naming the default
in the schema is the fix in that case too, and it is correct on every server
rather than on the ones where the binding happens to exist.

The predicate is the B<rendered> default clause, not C<default_value> itself,
because L<DBIO::Sybase::DDL/sybase_default_clause> renders nothing for the
literal string C<'null'>. That case reaches the server as the very statement
it rejects, and it is a contradiction in the model besides -- a column that
forbids nulls defaulting to one.

=head1 THE DESIRED-STATE CONTRACT APPLIES TO RENDERING TOO

C<as_sql> reads the target the way L<DBIO::Diff::Compare/changed_fields> reads
it when deciding this op exists at all: a field the target leaves C<undef> was
not prescribed, so the live value stands. That is applied per B<field>, not per
hashref -- C<data_type>, C<size> and C<not_null> each fall back to the C<from>
side on their own.

C<not_null> is the field where it matters most. Core lists it among the
desired-state-skippable scalars, so a target that does not prescribe it
produces no C<not_null> entry in the changed-field list and the op exists
because some I<other> attribute moved. Reading it from the target alone then
meant a type-only or default-only alter emitted the database's null default
over a live C<NOT NULL> column, silently, on a statement nobody asked to change
the nullability at all.

C<default_value> is deliberately B<not> read through that fallback. Re-stating
the live default is not the harmless no-op it looks like -- in this dialect it
is a second statement, and one ASE can refuse (see L</THE ALTER IS A MODIFY,
THE DEFAULT IS A SEPARATE REPLACE>). "This column should have no default" is
expressible: the comparator reports a default the target dropped (a live
C<DEFAULT NULL> counts as none), and the op removes it with C<< alter table t
replace c default null >>, the Reference Manual's own spelling. The live
default is never restated.

=head1 THE ALTER IS A MODIFY, THE DEFAULT IS A SEPARATE REPLACE

ASE has no C<ALTER COLUMN>. That spelling is Transact-SQL's -- it is what
L<DBIO::MSSQL::Diff::Column> emits -- and it appears nowhere in the ASE C<alter
table> entry, in any version consulted. The subclause that changes an existing
column is C<modify>, and the one that changes an existing column's default is
C<replace>. Verbatim from the Reference Manual: Commands, C<alter table> (16.0),
with the alternatives not at issue elided:

    alter table [[database.][owner].]table_name
      ...
      | modify column_name
          [datatype [null | not null]]
          ...
      | replace column_name
          default {constant_expression | user | null}
          ...

Both hang off C<alter table> itself, so nothing stands between the table name
and the keyword. The manual's own examples are
C<< alter table authors modify city varchar (30) null >> and
C<< alter table authors replace phone default null >>.

The two lines quoted above are spelled the same way in the 15.5 entry. The 15.0
entry differs in one respect, and only in the direction this class already
takes: there the datatype is not bracketed --
C<< modify I<column_name> I<datatype> [null | not null] >> -- so on that server
a C<modify> naming no type does not parse at all.

A C<DEFAULT> written inside the C<modify> is not a second spelling of that
second statement; it is not in the production at all. The parameter list keeps
the two apart in one sentence each -- C<modify>: "Specifies the name of the
column for which you are changing the datatype or nullability"; C<replace>:
"Specifies the column for which to replace the default value with the new value
specified by a following default clause".

=head2 Two statements, not one

C<alter table> does take several subclauses at once, but the sentence that
allows it rules out this pairing twice over: "add, drop, modify, and lock
subclauses are useful when changing an existing table's schema. A single
statement can contain any number of these subclauses, in any order, as long as
the same column name is not referenced more than once in the statement"
(Reference Manual: Commands, C<alter table>, "Altering Table Schema").
C<replace> is not among the four named, and a combined statement would name one
column twice, which is forbidden even for the four that are.

So a default change is rendered as a second statement, separated by C<;> --
the shape L<DBIO::Sybase::Diff::Index>'s C<alter> already emits for its
C<DROP INDEX> / C<CREATE INDEX> pair, and the separator the apply path reads:
L<DBIO::Deploy::Base/_execute_ddl> splits the migration on C<;>, so two
statements sharing a line become two C<< $dbh->do >> calls.

=head2 When the replace is emitted

Only when the target prescribes a default I<and> the B<rendered> clause differs
from the live column's -- never as a restatement of the default already there.
The predicate is the rendered clause for the same reason the C<add>'s refusal
uses it: L<DBIO::Sybase::DDL/sybase_default_clause> renders nothing for the
literal C<'null'>, and comparing C<default_value> directly would compare two
C<SCALAR> refs by address rather than by the expression they carry.

Emitting it on every alter of a defaulted column would look like the safer
choice and is not: a column whose default was bound with C<sp_bindefault>
B<rejects> the statement -- "You cannot replace a user-defined default bound to
the column with sp_bindefault", and "First use sp_unbindefault to unbind the
default" (Reference Manual: Commands, C<alter table>, "Changing Defaults"). A
redundant C<replace> would turn a migration that had nothing to do on that
column into a failing one.

The manual's list of what a modified table keeps -- "The modified table
retains the existing space management properties (max_rows_per_page,
fillfactor, and so on) and indexes of the table" (same entry, "Altering Table
Schema") -- does not name a column's default, which left open whether a
C<modify> drops it and a type-only alter would then have to put it back. Live on
ASE 16.0 SP02 it does not: a column with default C<'old'>, modified to
C<varchar(32) null>, still inserted C<'old'>.

=head2 A default-only change is the replace alone

When the comparator (L<DBIO::Diff::Compare/changed_column_fields>) reports
nothing but C<default_value> as changed, the C<modify> is left out and the
alter is the C<replace> statement alone -- C<< ALTER TABLE t REPLACE name
DEFAULT 'new' >>, summarised as C<< ALTER TABLE t REPLACE name >>. The
C<modify> would only restate a type, width and nullability that did not move,
and it is not free: a data copy "is required ... for most alter table ...
modify commands" (same entry, "Altering Table Schema"). Live on ASE 16.0 SP02 a
C<replace> changes the default with no C<modify> before it.

C<as_sql> asks the comparator itself, with the same call C<diff> makes, rather
than re-deciding which fields moved; the test is a set test ("everything
changed except C<default_value>" is empty), not a position in the list. A
default-only change that renders no C<replace> -- the literal C<'null'> --
falls back to the C<modify> it has always emitted, so the op never renders as
an empty statement.

An expression default is a SCALAR ref, and C<diff> hands the comparator the
SQL behind it rather than the ref, whose string is its address: the catalog
fetch of L<DBIO::Sybase::Introspect::Columns> reads every C<DEFAULT getdate()>
that way on both sides of a deploy diff, and two equal expressions must not be
a change. An expression and a literal of the same text still
differ -- one renders unquoted, the other quoted.

Dropping a default is not emitted at all. ASE spells it
C<< replace I<col> default null >>, but core's comparator skips an C<undef>
C<default_value> on the target, so the drift never reaches this class -- and
the literal C<'null'>, the one value that could stand for it in the model, is
exactly what C<sybase_default_clause> renders as no clause.

=head1 THE DROP NAMES THE COLUMN AND NOTHING ELSE

A dropped column renders as C<< ALTER TABLE t DROP old >>, with no C<COLUMN>
keyword. The C<drop> subclause has two arms and keywords only one of them --
verbatim from the Reference Manual: Commands, C<alter table> (16.0):

    | drop {column_name [, column_name]... | constraint constraint_name}

So C<drop constraint> is spelled out -- which is what
L<DBIO::Sybase::Diff::ForeignKey>'s drop already emits -- while a column is
named bare. The 15.5 entry publishes that line unchanged, and its own worked
example drops three columns without the keyword:
C<< alter table titles drop advance, notes, contract >>. The Transact-SQL
User's Guide states the column arm on its own,
C<< alter table I<table_name> drop I<column_name> [, I<column_name>] >>, with
the same example.

C<DROP COLUMN> is Transact-SQL's spelling -- it is what
L<DBIO::MSSQL::Diff::Column> emits -- and it is the same import as the
C<ALTER COLUMN> corrected above, arriving at a different subclause. Only
C<as_sql> carried it: this class's C<summary> has said C<< DROP old >> since
the file was written, so the two methods spelled one statement two ways.

The production takes several columns per statement --
C<< column_name [, column_name]... >> -- and this class still emits one
statement per dropped column. That is a compact form of the grammar left
unused, not a form the grammar refuses; whether the diff should batch drops
is a question about op granularity and is deliberately not answered here.

=head1 DATA-COPYING ALTERS NEED A DATABASE OPTION

Several of the statements this class renders make ASE copy the table: a
C<drop>, a C<modify> that changes the stored type (C<INT> to C<BIGINT>), and an
C<add> of a C<NOT NULL> column (with the default it needs). In a database
where neither option below is in effect, each fails with Msg 11052 (live, ASE
16.0 SP02, a database fresh from C<CREATE DATABASE>, table holding one row):

    Neither the 'select into' nor the 'full logging for alter table'
    database options are enabled for database 'k50_a'. ALTER TABLE with
    data copy cannot be done.

A change that needs no copy -- widening a C<VARCHAR>, a C<replace> of the
default, a nullable C<add> -- runs regardless.

What makes them run is C<select into/bulkcopy/pllsort> on the target database.
C<full logging for alter table>, the other option the message names, is
B<not> a substitute on every database: it applies only to a database whose log
is on its own device (C<log on> at C<CREATE DATABASE>), and on a database with
mixed data and log segments -- what a plain C<CREATE DATABASE> gives -- ASE
accepts the setting, says it "will be ignored while the log and data segments
remain mixed", and the C<alter> fails as before. A system administrator turns
the option on from C<master> and checkpoints the database for it to take
effect:

    use master
    exec sp_dboption 'mydb', 'select into/bulkcopy/pllsort', true
    use mydb
    checkpoint

C<select into/bulkcopy/pllsort> permits minimally logged operations, and the
transaction log of such a database cannot be dumped until the next full
database dump; whether that is acceptable is the administrator's decision.
This driver neither sets the option nor checks for it before applying a diff.
Because L<DBIO::Sybase::Deploy/apply> is not transactional, a diff that meets
the error part way stops there, with every statement before it applied -- see
L<DBIO::Sybase::Deploy/Data-copying ALTER TABLE>.

=head1 LIMITS

Every statement here is written against the documented grammar; none of it has
been executed against a server -- this driver's live suite exercises storage,
not the introspect/diff path. All three forms above are therefore B<sourced,
not verified>: the C<add>'s clause order and default requirement, the
C<alter>'s split into C<modify> plus C<replace>, and the C<drop>'s bare column
name, are quoted from the Reference Manual, and no ASE has confirmed that a
server accepts what those quotations were read to mean.

Two facts about the C<alter> have since been checked by hand on ASE 16.0 SP02:
a C<replace> alone changes the default, and a C<modify> keeps it. That is a
probe, not a suite -- the statements this class renders still are not run by
anything automated.

Independent of spelling: "You cannot run alter table from inside a transaction"
-- verbatim in the 15.0 and 15.5 entries, which carry the whole command on one
page; the 16.0 entry is split into subsections and its "Restrictions for alter
table" does not repeat the sentence. That is what
L<DBIO::Sybase::Storage::ASE>'s C<< _use_transactional_ddl(0) >> keeps core's
deploy path from doing. The data copy above additionally needs
C<select into/bulkcopy/pllsort> turned on in the database ("If alter table
performs a data copy, select into/bulkcopy/pllsort must be turned on in the
database that includes the table whose schema you are changing" -- same
section; measured live, see L</DATA-COPYING ALTERS NEED A DATABASE OPTION>).
A narrowing modify fails outright if any existing row holds C<NULL>
where C<not null> is being asked for, or data too wide for a reduced length.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
