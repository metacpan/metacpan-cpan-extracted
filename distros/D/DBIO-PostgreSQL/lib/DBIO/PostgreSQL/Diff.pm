package DBIO::PostgreSQL::Diff;
# ABSTRACT: Compare two introspected PostgreSQL models

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Base';


use DBIO::PostgreSQL::Diff::Schema    ();
use DBIO::PostgreSQL::Diff::Table     ();
use DBIO::PostgreSQL::Diff::Column    ();
use DBIO::PostgreSQL::Diff::View      ();
use DBIO::PostgreSQL::Diff::Type      ();
use DBIO::PostgreSQL::Diff::Sequence  ();
use DBIO::PostgreSQL::Diff::SequenceOwner ();
use DBIO::PostgreSQL::Diff::Index     ();
use DBIO::PostgreSQL::Diff::ForeignKey ();
use DBIO::PostgreSQL::Diff::Function  ();
use DBIO::PostgreSQL::Diff::Trigger   ();
use DBIO::PostgreSQL::Diff::Policy    ();
use DBIO::PostgreSQL::Diff::Extension ();
use DBIO::PostgreSQL::Util ();

my %_REGISTRY = (
  extensions => 'DBIO::PostgreSQL::Diff::Extension',
  schemas    => 'DBIO::PostgreSQL::Diff::Schema',
  types      => 'DBIO::PostgreSQL::Diff::Type',
  sequences  => 'DBIO::PostgreSQL::Diff::Sequence',
  functions  => 'DBIO::PostgreSQL::Diff::Function',
  tables     => 'DBIO::PostgreSQL::Diff::Table',
  columns    => 'DBIO::PostgreSQL::Diff::Column',
  sequence_owners => 'DBIO::PostgreSQL::Diff::SequenceOwner',
  views      => 'DBIO::PostgreSQL::Diff::View',
  indexes    => 'DBIO::PostgreSQL::Diff::Index',
  foreign_keys => 'DBIO::PostgreSQL::Diff::ForeignKey',
  triggers   => 'DBIO::PostgreSQL::Diff::Trigger',
  policies   => 'DBIO::PostgreSQL::Diff::Policy',
);

# The order of dependency: each section after the ones it can depend on.
# Creates and changes run through it forwards, removals backwards -- see
# ORDER OF OPERATIONS. Schemas stand ahead of extensions because an extension
# depends on the schema it is installed into (pg_depend, deptype n), not the
# other way round (karr k106). Views stand behind the columns because a view
# reads columns, also ones that are added to a table that is there, and ahead
# of the indexes and triggers because a materialized view has indexes and a
# view has triggers (karr k100). Sequences stand ahead of the functions and
# the tables because a column default and the body of a function call a
# sequence by name, and what a sequence belongs to stands behind the columns
# because it can be given to a column only when that is there (karr k121).
my @_ORDER = qw(
  schemas extensions types sequences functions tables columns sequence_owners
  views indexes foreign_keys triggers policies
);

# The section of the model a class reads when it is not the one of its own
# name: the model has no "views", it files a view among the tables, by kind,
# and what a sequence belongs to is in its entry among the sequences.
my %_MODEL_SECTION = (
  views           => 'tables',
  sequence_owners => 'sequences',
);

# Trailing context each table-aware diff class needs after its own
# (source, target) section pair. Diff::Table builds full CREATE TABLE
# statements and therefore needs the *column* data; Diff::Column and
# Diff::Policy need the *table* list for schema/table context; Diff::Index
# needs the *table* list to detect which tables are being dropped in the
# same pass, so it can suppress standalone DROP INDEX ops that DROP TABLE
# already covers (karr k32). Diff::Schema needs the *extension*
# list to see an extension it would drop along with a schema, and the
# *outside_dependents* for what stands in it (karr k152), as do Diff::Table
# and Diff::Type for what stands on a table or a type. Diff::Sequence reads
# the *schemas*, for the sequences of a schema that is dropped. Diff::Trigger
# needs the *table* list to see which views are dropped and created again,
# their triggers with them. Diff::Column also reads the *types*, to tell
# whether two composite types have the same attributes (karr k121).
# Diff::Table reads the *foreign_keys*, for the order of SET LOGGED / SET
# UNLOGGED (karr k121). Diff::Column reads the *policies*, *triggers* and
# *outside_readers* for what stops a column from changing its type
# (karr k121). A value
# that is a list names several sections, each handed over as its own
# (source, target) pair.
my %_AUX_SECTION = (
  schemas  => [qw( extensions outside_dependents )],
  types    => 'outside_dependents',
  sequences => 'schemas',
  tables   => [qw( columns foreign_keys outside_dependents )],
  columns  => [qw( tables types policies triggers outside_readers )],
  views    => 'columns',
  indexes  => 'tables',
  foreign_keys => 'tables',
  triggers => [qw( tables columns )],
  policies => 'tables',
);

sub _diff_registry { %_REGISTRY }
sub _diff_order    { @_ORDER    }


sub diff_options { qw(foreign_keys_not_valid) }


sub register_diff_class {
  my ($class, %args) = @_;
  my $key      = $args{model_key} or die 'model_key required';
  my $diff_cls = $args{class}     or die 'class required';
  my $position = $args{position};

  $_REGISTRY{$key} = $diff_cls;
  @_ORDER = grep { $_ ne $key } @_ORDER;

  if (!defined $position) {
    push @_ORDER, $key;
  } elsif ($position =~ /\Aafter:(.+)\z/) {
    my $anchor = $1;
    my ($i) = grep { $_ORDER[$_] eq $anchor } 0..$#_ORDER;
    die "position anchor '$anchor' not found in diff order" unless defined $i;
    splice @_ORDER, $i + 1, 0, $key;
  } elsif ($position =~ /\Abefore:(.+)\z/) {
    my $anchor = $1;
    my ($i) = grep { $_ORDER[$_] eq $anchor } 0..$#_ORDER;
    die "position anchor '$anchor' not found in diff order" unless defined $i;
    splice @_ORDER, $i, 0, $key;
  } else {
    die "invalid position '$position' — use 'after:KEY' or 'before:KEY'";
  }
}

# True for an operation that takes an object away for good: a drop that is
# not the first half of a drop-and-recreate.
sub _is_removal {
  my ($op) = @_;
  return 0 unless $op->can('action') && ($op->action // '') eq 'drop';
  return 0 if $op->can('replaced') && $op->replaced;
  return 1;
}

sub _build_operations {
  my ($self) = @_;
  my (@build, @remove, @rebuild_drops);
  my $tables_at;

  for my $key (@_ORDER) {
    # Where the changes to tables and columns begin: the views that are
    # dropped and created again have to be gone by then.
    $tables_at = @build if $key eq 'tables';

    my $diff_cls = $_REGISTRY{$key} or next;
    my $section  = $_MODEL_SECTION{$key} // $key;
    next unless exists $self->source->{$section} || exists $self->target->{$section};

    # A target without the section says nothing of foreign keys; it does not
    # declare there are none (a model built by hand, target_from_compiled).
    next if $key eq 'foreign_keys' && !exists $self->target->{foreign_keys};

    my @extra;
    if (my $aux = $_AUX_SECTION{$key}) {
      my @aux = ref $aux ? @$aux : ($aux);
      @extra = map { ($self->source->{$_} // {}, $self->target->{$_} // {}) } @aux;
    }

    # The extension protocol (ADR 0066) is asked about the change of a
    # column's type: the columns are the one class that takes it.
    push @extra, $self->{extensions} if $key eq 'columns';

    # The indexes are asked whether a foreign key that points at a constraint
    # to drop goes first. A target without the section declares no keys, which
    # is not the same as none left, so the sections go over as they are.
    push @extra, $self->source->{foreign_keys}, $self->target->{foreign_keys} if $key eq 'indexes';

    my ($from, $to) = ($self->source->{$section} // {}, $self->target->{$section} // {});

    # A key into a table in neither model is not the deploy's: not compared,
    # not dropped, named in the summary.
    if ($key eq 'foreign_keys') {
      my @kept;
      ($from, $to, @kept) = $diff_cls->split_outside($from, $to, @extra);
      $self->{kept_foreign_keys} = \@kept;
    }

    my @ops = $diff_cls->diff($from, $to, @extra);

    @ops = $diff_cls->with_validation(@ops)
      if $key eq 'foreign_keys' && $self->{foreign_keys_not_valid};

    # Creates and changes in the order of dependency; removals in the
    # reverse -- each section's ahead of those of the sections before it --
    # and after everything that is created or changed.
    if ($key eq 'views' && defined $tables_at) {
      # The drops of the views that are created again stand ahead of the
      # tables and columns, not behind them: PostgreSQL does not alter the
      # type of a column while a view reads it (karr k120).
      push @rebuild_drops, grep {  $_->can('replaced') && $_->replaced } @ops;
      @ops = grep { !($_->can('replaced') && $_->replaced) } @ops;
    }
    push    @build,  grep { !_is_removal($_) } @ops;
    unshift @remove, grep {  _is_removal($_) } @ops;
  }

  splice @build, $tables_at // 0, 0, @rebuild_drops;

  return [ @build, @remove ];
}


sub summary {
  my ($self) = @_;
  my $text = $self->SUPER::summary;
  $self->operations;
  my @kept = map { $_->summary } @{ $self->{kept_foreign_keys} // [] };
  return join "\n", grep { length } $text, @kept;
}


# The adapter's native_type the way pg_catalog.format_type reports it back,
# where the two differ: timestamptz is "timestamp with time zone" there, with
# its precision behind the first word, and a numeric with a precision alone
# has the scale 0.
sub _format_type_of_native {
  my ($native) = @_;
  return DBIO::PostgreSQL::Util::type_with_modifier('timestamp with time zone', $1)
    if $native =~ /\Atimestamptz(?:\((\d+)\))?\z/;
  return "numeric($1,0)" if $native =~ /\Anumeric\((\d+)\)\z/;
  return $native;
}

# Render a default value in the same string form that pg_get_expr reports
# back from pg_attrdef, so the synthesized target model round-trips against
# the live (introspected) source. Returns undef when there is no default.
#
#   $c->{default} shape (from DBIO::Schema::Type::canonical_column):
#     undef         -- no default
#     \"now()"      -- SCALAR ref holding a raw PG expression
#     \"5"          -- SCALAR ref holding a numeric literal
#     "draft"       -- plain string (a text/varchar literal in single quotes)
#
# pg_get_expr output for common cases:
#     text 'draft'   -> "'draft'::text"            (string + ::textype)
#     numeric 42     -> "42"                        (number, no cast)
#     now()          -> "now()"                     (expression, unchanged)
#     nextval seq    -> "nextval('schema.seq'::regclass)"
sub _format_pg_default {
  my ($default, $data_type) = @_;
  return undef unless defined $default;

  # Only a scalar ref is an expression, written as given. A plain string is a
  # value: whatever it holds, it is written as a literal of the column's type.
  my $is_expr = ref $default eq 'SCALAR';
  my $expr = $is_expr ? $$default : $default;
  return undef unless defined $expr && length $expr;
  $expr =~ s/^\s+|\s+$//g;

  if (!$is_expr) {
    # a boolean column's true/false is what pg_get_expr prints, without a cast
    return lc $expr
      if $expr =~ /^(?:true|false)\z/i && ($data_type // '') =~ /^bool/i;
    my $cast = $data_type // 'text';
    $cast = "timestamp with time zone" if $cast eq 'timestamptz';
    return sprintf('%s::%s', DBIO::PostgreSQL::Util::quote_literal($expr), $cast);
  }

  # nextval() -- left untouched (matches pg_get_expr for IDENTITY-adjacent cols,
  # though those are handled via $identity above and not via default).
  return $expr if $expr =~ /\bnextval\s*\(/i;

  # Already a quoted string (e.g. DDL-emitted literal). Pass through as-is so
  # any embedded ::cast is preserved.
  return $expr if $expr =~ /^['"]/;

  # Already a quoted expression like 'now()' as a SCALAR ref string content
  # of a non-string column -- common case: default_value => \'now()'.
  # If it has parens or ::cast, leave alone.
  return $expr if $expr =~ /[()]/ || $expr =~ /::/;

  # Pure number or numeric expression -- PG renders numeric defaults
  # as a quoted literal with an explicit cast (e.g. '0'::bigint), not as
  # a bare number. The column type is *not* implied by the value.
  if ($expr =~ /^-?\d+(?:\.\d+)?\z/) {
    my $cast = $data_type // 'text';
    $cast = "timestamp with time zone" if $cast eq 'timestamptz';
    return sprintf('%s::%s', DBIO::PostgreSQL::Util::quote_literal($expr), $cast);
  }

  # Boolean literals -- PG renders as 'true' / 'false' / 'null' (no cast).
  return lc $expr if $expr =~ /^(?:true|false|null)\z/i;

  # Fallback: treat as a string literal, quoting and casting to the column
  # type. pg_get_expr appends '::textype' (the column's data_type string as
  # format_type renders it). Use the already-normalized $data_type. The
  # literal is the one install_ddl writes and pg_get_expr reports back: an
  # embedded apostrophe doubled.
  my $cast = $data_type // 'text';
  $cast = "timestamp with time zone" if $cast eq 'timestamptz';
  return sprintf('%s::%s', DBIO::PostgreSQL::Util::quote_literal($expr), $cast);
}

sub target_from_compiled {
  my ($class, $compiled) = @_;
  my (%tables, %columns, %indexes);

  # The public schema always exists in PostgreSQL; include it so the schema
  # diff does not emit a spurious DROP SCHEMA public.
  my %schemas = ( public => {} );

  for my $tname (keys %{ $compiled->{tables} // {} }) {
    my $t   = $compiled->{tables}{$tname};
    my $key = "public.$tname";

    $tables{$key} = {
      schema_name => 'public',
      table_name  => $tname,
      kind        => 'r',
    };

    my @cols;
    my @pk_cols;
    for my $c (@{ $t->{columns} // [] }) {
      my $native = $c->{native_type};
      my $data_type = _format_type_of_native($native);

      my $identity      = undef;
      my $default_value = _format_pg_default($c->{default}, $data_type);

      if ($c->{auto_increment} && $c->{is_pk}) {
        # Deploy as GENERATED ALWAYS AS IDENTITY; PG reports identity='a' and no default.
        $identity      = 'a';
        $default_value = undef;
      }
      elsif ($c->{auto_increment}) {
        # Non-PK auto-increment: DDL.pm emits GENERATED BY DEFAULT AS IDENTITY,
        # and PG reports attidentity='d' with no default expression.
        $identity      = 'd';
        $default_value = undef;
      }

      push @cols, {
        column_name   => $c->{column_name},
        data_type     => $data_type,
        not_null      => ($c->{not_null} ? 1 : 0),
        default_value => $default_value,
        identity      => $identity,
        generated     => undef,
      };

      push @pk_cols, $c->{column_name} if $c->{is_pk};
    }
    $columns{$key} = \@cols;

    # PostgreSQL automatically creates a primary key index named <table>_pkey.
    # Include it in the target so the index diff does not flag it as dropped.
    # The definition string matches what pg_get_indexdef returns, enabling
    # the definition-based comparison in Diff::Index. pg_get_indexdef quotes
    # the index, the table and the columns by the rule of quote_ident(), so
    # the same rule writes them here: a reserved or Mixed-Case name would
    # otherwise differ from the server's text in nothing but its quotes, and
    # the index would be dropped and recreated on every diff.
    if (@pk_cols) {
      my $pkey_name = "${tname}_pkey";
      my $definition = sprintf 'CREATE UNIQUE INDEX %s ON %s USING btree (%s)',
        DBIO::PostgreSQL::Util::quote_ident($pkey_name),
        DBIO::PostgreSQL::Util::quote_qualified('public', $tname),
        join(', ', map { DBIO::PostgreSQL::Util::quote_ident($_) } @pk_cols);
      $indexes{$key}{$pkey_name} = {
        schema_name   => 'public',
        table_name    => $tname,
        index_name    => $pkey_name,
        access_method => 'btree',
        is_unique     => 1,
        is_primary    => 1,
        is_valid      => 1,
        definition    => $definition,
        predicate     => undef,
        expressions   => undef,
        columns         => \@pk_cols,
        include_columns => [],
        storage_params  => {},
        opclasses       => {},
        sort_options    => {},
        constraint_name => $pkey_name,
        constraint_type => 'p',
        referenced_by   => [],
      };
    }
  }

  return {
    tables           => \%tables,
    columns          => \%columns,
    schemas          => \%schemas,
    extensions       => {},
    types            => {},
    functions        => {},
    indexes          => \%indexes,
    triggers         => {},
    policies         => {},
    sequences        => {},
    check_constraints => {},
  };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff - Compare two introspected PostgreSQL models

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::PostgreSQL::Diff> compares two introspected PostgreSQL database models
(as produced by L<DBIO::PostgreSQL::Introspect>) and produces a list of
structured diff operations. These operations can then be rendered to SQL or a
human-readable summary.

    my $diff = DBIO::PostgreSQL::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

C<summary> and C<as_sql> give the operations in the same order, so review
output and executable output stay aligned. That order is the subject of
L</ORDER OF OPERATIONS>.

The argument C<extensions> is the L<DBIO::Extension::Protocol> of the schema's
declared database extensions, which L<DBIO::Deploy::Base/diff> passes when the
schema declares any. The diff asks it about a change of a column's type and
writes or refuses the change as it answers
(L<DBIO::PostgreSQL::Diff::Column/diff>). Without it nothing is asked.

=head1 METHODS

=head2 diff_options

    my @names = DBIO::PostgreSQL::Diff->diff_options;   # ('foreign_keys_not_valid')

The options this diff class takes in C<new> beside C<source>, C<target> and
C<extensions>. L<DBIO::Deploy::Base/diff> hands a caller's options on only when
they are listed here.

=head2 register_diff_class

    DBIO::PostgreSQL::Diff->register_diff_class(
        model_key => 'spatial_refs',
        class     => 'DBIO::PostgreSQL::PostGIS::Diff::SpatialRef',
        position  => 'after:indexes',
    );

Register a Diff class for a model key. Use C<position> (C<after:KEY> or C<before:KEY>) to control ordering.

The position is a place in the order of dependency (L</ORDER OF OPERATIONS>),
so it holds for both halves: what the class creates or changes comes after
the creates of C<KEY>, what it removes comes I<before> the removals of C<KEY>.
An operation is a removal when its C<action> is C<drop>; a class that drops
an object only to create it again in the same diff gives that C<drop> a true
C<replaced>, and it stays ahead of its C<create>.

=head2 summary

One line per operation, then one line per foreign key kept because its
referenced table is in neither model (C<=fk: ... -- kept (target outside the
deploy)>). Such a line is no operation: it has no statement, is not in
C<operations> and does not make C<has_changes> true.

=head2 target_from_compiled

    my $target = DBIO::PostgreSQL::Diff->target_from_compiled($compiled_model);

Translates the neutral model from L<DBIO::Schema::ModelCompiler> into the
PostgreSQL introspect-shaped model that C<diff> consumes.

The compiled model uses C<native_type> (as produced by
L<DBIO::PostgreSQL::Adapter>). This method translates that into the exact
C<data_type> strings that L<DBIO::PostgreSQL::Introspect::Columns> returns
(i.e. whatever C<pg_catalog.format_type> reports), keys tables as
C<"public.$table_name">, and populates all top-level sections the Diff
engine dereferences so that no spurious diffs arise from missing keys.

The model has no C<foreign_keys> section: the compiled model carries no
relationships, so it does not declare that there are none.

Auto-increment primary-key columns are mapped to C<identity = 'a'>
(C<GENERATED ALWAYS AS IDENTITY>), which is the canonical DBIO convention
for integer PKs in PostgreSQL.

Every entry of the compiled model becomes a table (C<< kind => 'r' >>). The
compiled model does not tell a view from a table -- a
L<DBIO::ResultSource::View> source arrives in it as one more table, without
its definition -- so a schema with a deployed view cannot be diffed through
this method: the view would be compared, and created, as a table.
L<DBIO::PostgreSQL::Deploy/diff> does not use it; its target is introspected
from a temporary database, where a view is a view.

=head1 THE TWO MODELS

A column type, a default, the definition of an index, a trigger or a function
are compared as the text the model has, and that text is what C<as_sql>
writes. PostgreSQL writes it for the session that asks, a name without its
schema whenever that session's C<search_path> finds it. So both models are
read with L<DBIO::PostgreSQL::Introspect/qualified_names>, which is on by
default: then one object is one text in both, and a statement made of it
reaches the objects it names in whatever session it is run.

Two models read with C<< qualified_names => 0 >> are comparable only when
they were read under the same C<search_path>, and their statements run as
meant only under that one.

=head1 ORDER OF OPERATIONS

The operations come in two halves, and the order within each follows what
depends on what.

First everything that is created or changed, in the order of dependency:
schemas, extensions, types, sequences, functions, tables, columns, what a
sequence belongs to, views, indexes, foreign keys, triggers, policies. A schema comes before the extension that is installed
into it -- C<age> wants C<ag_catalog>, C<postgis_topology> wants C<topology>,
and C<CREATE EXTENSION> uses a schema that is there instead of failing over
it -- and an extension before the types, functions and tables that use what
it brings. A sequence comes ahead of the tables and columns whose default
calls it, and is given to its column (C<ALTER SEQUENCE ... OWNED BY>) once
that column is there; see L<DBIO::PostgreSQL::Diff::Sequence>. A view comes
after the tables it reads and after the columns that
are added to them, and before the indexes of a materialized view and the
triggers of a view. Within the tables, C<SET LOGGED> and C<SET UNLOGGED> go in
the order of the foreign keys: going to unlogged the table that holds the key
ahead of the one it references, going to logged the referenced one first,
which is the only order PostgreSQL takes (L<DBIO::PostgreSQL::Diff::Table/diff>).

Then everything that goes away, in the reverse order: policies, triggers,
foreign keys, indexes, views, columns, tables, functions, types, extensions, schemas. No
sequence is dropped by itself (L<DBIO::PostgreSQL::Diff::Sequence/What is not
done>), except one no column owns in a schema that is dropped; the one a column owns
goes with the column or the table. What a
sequence belongs to is changed in the first half, ahead of these drops, so a
sequence that stays is not taken along. So a
table is dropped before the schema it is in, a trigger before the function it
calls, an index before its column, a view before the column and the table it
reads, a column before its type, and whatever hangs on an extension before
the extension.

The drops come after the creates and changes, not before, because a change is
what takes the last user off an object: a column is altered to its new type
before the old type is dropped, a trigger is pointed at the new function
before the old one goes. C<DROP TYPE> ahead of the C<ALTER> would meet the
column that is still of the type.

An operation counts as a removal when its C<action> is C<drop>. One kind of
drop is none: the first half of a drop-and-recreate, as
L<DBIO::PostgreSQL::Diff::Index>, L<DBIO::PostgreSQL::Diff::Trigger> and
L<DBIO::PostgreSQL::Diff::View> emit for a changed definition. Such an
operation answers true to C<replaced> and stays where its class put it, ahead
of the C<create> that follows.

Within one section the operations stay in the order their class returned
them. That is by name, except for extensions, which
L<DBIO::PostgreSQL::Diff::Extension> orders by the dependencies between them,
for views, which L<DBIO::PostgreSQL::Diff::View> orders by the views they
read, and for columns, where L<DBIO::PostgreSQL::Diff::Column> puts a table
behind the tables it has columns from.

What the order does not know is a dependency the model does not carry: a
function that calls another, a function or a column default that reads a
view, a new object that wants the name of one dropped in the same diff, a
foreign key between a logged and an unlogged table. PostgreSQL
refuses such a statement, C<apply> dies on it, and the transaction it ran in
is rolled back (L<DBIO::Deploy::Base/_execute_ddl>).

A column whose type changes while a policy, a trigger (its C<WHEN> or C<UPDATE
OF>), a generated column or a view outside the declared schemas reads it is not
in that list: the model carries these dependencies
(C<depends_on_columns> of L<DBIO::PostgreSQL::Introspect::Policies>,
L<DBIO::PostgreSQL::Introspect::Triggers> and
L<DBIO::PostgreSQL::Introspect::Columns>, and the C<outside_readers> section,
L<DBIO::PostgreSQL::Introspect::OutsideReaders>), and the diff is refused
(L</WHAT IS REFUSED>). What a trigger's function or the body of any function
reads is still not known.

Where the model carries the dependency and a plain order cannot satisfy it,
the diff takes the views out of the way: a column that changes its type while a
view reads it is altered between the C<DROP VIEW> of every view that reads it
(and of the views on those) and their C<CREATE VIEW>, because PostgreSQL does
not alter the type of a column a view uses (L<DBIO::PostgreSQL::Diff::View/diff>).
The drops of the views that are created again therefore stand ahead of the
changes to tables and columns, not behind the columns. Only the target's views
are created again; a view only the database has is refused, and so is a
materialized view that reads the column or stands on a view that does
(L</WHAT IS REFUSED>).

A column a partition has from the partitioned table, or a table from one it
inherits from, is changed there and nowhere else: PostgreSQL carries the
change down, and what is the table's own is changed after that
(L<DBIO::PostgreSQL::Diff::Column/Partitions and tables that inherit>).

An index or trigger on a partitioned table is the same: the server carries it
down to every partition as a copy, and the copy is not in the model
(L<DBIO::PostgreSQL::Introspect::Indexes>,
L<DBIO::PostgreSQL::Introspect::Triggers>), so the diff writes a trigger, and the
drop of an index, at the partitioned table alone and never one at a partition
for a copy. An index or trigger a partition has of its own is in the model and
is diffed.

The create of an index on a partitioned table is the exception: the text of the
catalog, C<ON ONLY>, makes an index that is invalid until every partition has
an index attached, so the diff writes besides it a C<CREATE INDEX> at each
partition and C<ALTER INDEX ... ATTACH PARTITION>
(L<DBIO::PostgreSQL::Diff::Index/diff>).

No drop is written with C<CASCADE>: a schema, a table and a type are dropped
the way PostgreSQL drops them by default (C<RESTRICT>), which refuses while
anything depends on the object. The order above means that by then everything
the model knows in or on the object is gone already: a table's foreign keys and
the ones that point at it, the views that read it, the types and functions of a
schema, its tables and the sequences no column owns, the columns that are of a
type. What a table owns outright -- its indexes, triggers, policies, its own
constraints and the sequences its columns own -- goes with it and is not
dropped by itself (L<DBIO::PostgreSQL::Diff::Index/diff>). Two tables that
reference each other lose their keys first, a table that inherits from another
goes ahead of it, and a type goes ahead of the types built on it.

What depends on the object and the model does not hold is named before any
statement is written: a view or materialized view, a foreign key, a partition
or an inheriting table of a schema outside C<pg_schemas> on a dropped table; a
column, a routine or a domain there on a dropped type; a domain, operator,
collation or the like in a dropped schema. The diff is refused with their names
(L<DBIO::PostgreSQL::Diff::Dependents>, read into the C<outside_dependents>
section by L<DBIO::PostgreSQL::Introspect::OutsideDependents>). Without that
section -- a model built by hand -- nothing is asked, and whatever the server
refuses stops the statement: C<apply> dies on it and its transaction is rolled
back (L<DBIO::Deploy::Base/_execute_ddl>). Where the diff would drop a schema
that holds an extension it keeps, it is refused too: see
L<DBIO::PostgreSQL::Diff::Schema/diff>.

=head1 WHAT APPLY ASKS FOR

L<DBIO::PostgreSQL::Deploy> inherits C<apply> and C<upgrade> from
L<DBIO::Deploy::Base>. Before the first statement the base reads this diff:
every operation whose C<action> is C<drop> and that is not the first half of a
drop and create (C<replaced>) is destructive, and so is a column operation
that answers true to C<lossy> -- a change of type that may alter or lose a
stored value (L<DBIO::PostgreSQL::Diff::Column/lossy>). Such a diff runs with
C<< allow_destructive => 1 >>, given to C<apply> or C<upgrade> or set on the
deploy; without it the exception names each operation and no statement has run.
C<< dry_run => 1 >> executes nothing. A widening of C<smallint>, C<integer>,
C<bigint> or of the limit of a C<varchar> runs without the release. See
L<DBIO::Deploy::Base/apply>.

=head1 FOREIGN KEYS

A foreign key is compared and written by L<DBIO::PostgreSQL::Diff::ForeignKey>,
after the indexes (the key it points at exists) and dropped before them. The
target is what the install declared (C<pg_fk_constraints_from_rels>), so:

=over 4

=item * a key the target has and the database lacks is created, also on a
table the diff creates, with the name and the C<ON DELETE> / C<ON UPDATE> of
the install;

=item * a key with other columns, target or actions is dropped and created
again under its name;

=item * a key the schema does not declare is dropped, and the summary says
C<not declared by the schema, dropped>. A target model without a
C<foreign_keys> section (a model built by hand, L</target_from_compiled>) says
nothing of them, and none is dropped;

=item * a key whose referenced table is in neither model (a schema outside
C<pg_schemas>) is not the deploy's: it is neither compared nor dropped, and the
summary names it C<kept (target outside the deploy)>. A table only one model
has is inside the deploy, so a key into it is dropped as any other;

=item * the keys of a table that is dropped go with it.

=back

The option C<foreign_keys_not_valid> (set by L<DBIO::PostgreSQL::Deploy/foreign_keys_not_valid>,
or C<< Diff->new(foreign_keys_not_valid => 1) >>) adds the key of an existing
table C<NOT VALID> and a C<VALIDATE CONSTRAINT> after all of them. A key left C<NOT VALID> (a step run alone, or
an upgrade that stopped) is validated by the next diff, which reads
C<convalidated>; rows that break it fail that upgrade until they are cleaned up. A key the
database holds C<NOT VALID> that the target holds valid gets a C<VALIDATE
CONSTRAINT>, and C<MATCH FULL> and the column list of C<ON DELETE SET NULL
(columns)> are compared like the actions.
C<DEFERRABLE> and C<INITIALLY DEFERRED> of a foreign key and of a UNIQUE
constraint are compared and written.

An index or constraint a foreign key stands on is still refused when it is to
go while the key stays (L</WHAT IS REFUSED>). The index drop of a changed
index runs ahead of the drop of a foreign key; a layout this order cannot
express is a migration by hand in two steps.

=head1 WHAT IS REFUSED

A change the diff cannot make without losing what the database holds, or
without guessing at what the model does not carry, is not made at all. Building
the operations dies with C<refusing to diff: ...>, a message that names the
object and the reason and says what can be done about it, and no statement is
generated -- for nothing else in the diff either.

=over 4

=item * dropping a schema an extension the diff keeps is installed in
(L<DBIO::PostgreSQL::Diff::Schema/diff>)

=item * dropping a table, a type or a schema that objects outside the model
depend on -- the views, foreign keys, partitions and inheriting tables, the
columns, routines and domains, the domains, operators and the like of
L<DBIO::PostgreSQL::Introspect::OutsideDependents>. The message names each of
them (L<DBIO::PostgreSQL::Diff::Dependents>)

=item * a relation that is of another kind in the target -- a table where the
target has a view, a view where it has a materialized view; creating a foreign
table, a partitioned table, a partition or a table that inherits; a table
that is a partition, or inherits, on one side only or of another table; a
partitioned table or a materialized view that is unlogged on one side only
(L<DBIO::PostgreSQL::Diff::Table/diff>)

=item * a materialized view with another definition, or one the target keeps
on a view that has another definition (L<DBIO::PostgreSQL::Diff::View/diff>)

=item * a change to how an existing column is generated; a column that
changes its type while a view that only the database has, or any
materialized view, reads it or stands on a view that does; a column that changes from a composite type to one of other attributes; a column to add, to drop or to alter the type of at a partition, or at a
table that inherits it, and not at the table it comes from
(L<DBIO::PostgreSQL::Diff::Column/diff>)

=item * a change of a column's type that an extension of the schema refuses
(a verdict C<< { refuse => ... } >>); the message carries the refusal of every
column and extension
(L<DBIO::PostgreSQL::Diff::Column/diff>)

=item * a column that changes its type while a policy, a trigger (its C<WHEN>
or C<UPDATE OF>), a generated column, or a view or materialized view in a
schema outside the declared ones reads it. The message names the column, the
types and each object, and gives the statement that takes it out of the way
(C<DROP POLICY>, C<DROP TRIGGER>, C<ALTER TABLE ... DROP COLUMN>, C<DROP
VIEW>), after which the diff alters the column and creates again what the
target has
(L<DBIO::PostgreSQL::Diff::Column/A column that changes its type while something else reads it>)

=item * an extension the database has in another schema than the one
C<pg_extensions> declares, when it is not relocatable
(L<DBIO::PostgreSQL::Diff::Extension/diff>)

=item * a function, a trigger, an index or a view to create, or to create
again, that the target model has no definition for -- see L</An object
without a definition>

=item * an index that stands behind a PRIMARY KEY, UNIQUE or EXCLUDE
constraint and whose constraint cannot go with it (foreign keys of other
tables point at it and stay, or it is dropped and added again), or a constraint to create that the diff cannot write
(EXCLUDE; a key with an expression, a sort order or an operator class; a
second primary key under another name; an index of the database that
C<ADD CONSTRAINT ... USING INDEX> does not take: partial, not btree, not
valid, on a partitioned table). The message names the C<ALTER TABLE>
statements that settle it
(L<DBIO::PostgreSQL::Diff::Index/diff>)

=item * an aggregate or a window function to create, or one that is another
kind or has another definition in the target: the model holds no definition
of one, because C<pg_get_functiondef> raises an error for it. One that is the
same on both sides is no operation, and one only the database has is dropped
(C<DROP AGGREGATE> for an aggregate). A function that is a procedure in the target, or the other way
round, is not refused where the two signatures pair (they differ at most in the
mode C<IN>): it is dropped and created again
(L<DBIO::PostgreSQL::Diff::Function/diff>)

=item * a function that is a procedure in the target, or the other way round,
whose signatures do not pair (an C<INOUT> argument, an C<OUT> argument one side
has, another argument name) while their input argument types are the same:
PostgreSQL keeps one routine per name and input types, so the create would meet
the old routine and the server would refuse it when the statements run. The
message names both and the C<DROP> to run by hand first
(L<DBIO::PostgreSQL::Diff::Function/diff>)

=item * a type both sides have that is of another kind in the target, an
enum that has lost a value or has its values in another order, an enum or
composite type the target declares empty (no values, no attributes) where the
database has some (a drop would take the columns of the type with their data;
a type the target does not declare at all is dropped), a composite
type with other attributes (also the collation of an attribute), a range type
with another subtype, collation, operator class, canonical or subtype_diff
function. Only enum values added to the ones the database has are written,
each at its place in the target's order (C<BEFORE>/C<AFTER>)
(L<DBIO::PostgreSQL::Diff::Type/diff>)

=item * an object to create whose name differs only in upper and lower case
from one to drop -- see L</One name in two spellings>

=item * a sequence of its own to create under the name the database holds as
the sequence of an identity column, which is what an identity column made
C<serial> comes to; the message names the column and the way out, C<ALTER
TABLE ... ALTER COLUMN ... DROP IDENTITY>
(L<DBIO::PostgreSQL::Diff::Sequence/diff>)

=back

=head2 An object without a definition

A function, a trigger, an index and a view are written as the text the
catalog gives for them (C<pg_get_functiondef>, C<pg_get_triggerdef>,
C<pg_get_indexdef>, C<pg_get_viewdef>), and compared by it. Where the target
model has one of them without that text and the diff would have to write it
-- because the database does not have it, or has it with another definition
-- the diff is refused (L<DBIO::PostgreSQL::Diff::NoStatement>), by
L<DBIO::PostgreSQL::Diff::Function/diff>,
L<DBIO::PostgreSQL::Diff::Trigger/diff>,
L<DBIO::PostgreSQL::Diff::Index/diff> and L<DBIO::PostgreSQL::Diff::View/diff>.
No comment and no placeholder is written in the place of the statement, and
an index is not written from its columns: that would make a plain index of a
unique or a partial one.

The catalog has no definition for a function, a trigger or an index that is
gone by the time it is asked -- one another session dropped while the model
was read (L<DBIO::PostgreSQL::Diff::NoStatement/When the catalog has no
definition>). The model then still has the object, under its name. Reading
the model again is the way out. A view without a definition is in a model
built by hand only: for one that is gone the reading of the model dies.

Only the target's definition is asked for. An object the diff drops needs
none, and where only the model of the database lacks it the target's is
written, as for any object whose definition differs.

The same holds for an operation nobody diffed: one built with C<new> whose
C<as_sql> has no statement -- no definition, an C<action> or a kind its class
does not know, an C<alter> with nothing to alter, a column to add without a
C<data_type>, a range type without a C<subtype> -- dies there, and returns
neither a comment nor an empty string
(L<DBIO::PostgreSQL::Diff::NoStatement/throw>).

=head2 One name in two spellings

PostgreSQL reads a name written without quotes in lower case, so a database
may hold C<useraccount> where the schema declares C<UserAccount> -- one that
was deployed before this distribution wrote every name exactly, or one whose
tables somebody typed. The diff compares names as they are and finds a table
to create and another to drop. It does not know whether the two are one
table; if they are, C<DROP TABLE> takes the rows.

So where an object to create and an object to drop have the same name but
for upper and lower case, in the same place -- two tables of one schema, two
columns of one table -- and dropping it loses something or cannot be done,
the diff is refused. The rule is L<DBIO::PostgreSQL::Diff::CaseOnly>'s; the
message names both spellings, for every such object of that kind, and the
C<RENAME> that makes the one into the other. The diff does not write the
C<RENAME> itself.

=over 4

=item * a schema -- the drop is preceded by that of everything in it
(L<DBIO::PostgreSQL::Diff::Schema/diff>). Schemas are looked at first, so a
schema in another spelling is reported as that and not table by table.

=item * a table, a foreign table, a partitioned table, a materialized view --
the drop takes the rows, or the data and the indexes
(L<DBIO::PostgreSQL::Diff::Table/diff>)

=item * a column (L<DBIO::PostgreSQL::Diff::Column/diff>)

=item * a type -- a drop of the old type meets the columns that are still of
it (L<DBIO::PostgreSQL::Diff::Type/diff>)

=item * an index that stands behind a PRIMARY KEY, UNIQUE or EXCLUDE
constraint (the model says which, see L<DBIO::PostgreSQL::Introspect::Indexes/fetch>)
-- PostgreSQL does not drop it by C<DROP INDEX>, and dropping the constraint
and creating another under the new spelling builds the index again, where a
rename keeps it
(L<DBIO::PostgreSQL::Diff::Index/diff>)

=back

For everything else such a pair is dropped and created like any other, which
PostgreSQL 18 runs through and which loses nothing the model holds: a view
(as with every view that is created again, the privileges granted on it and
its comment are not in the model and go), an index that is not unique, a
function, a trigger, a policy. An extension cannot be such a pair -- its name
is the one its control file has, in any database.

A name both sides have is never part of a pair. A target with C<users> and
C<Users> has two tables, and the diff creates the one that is missing.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::PostgreSQL::Deploy> - orchestrates introspection and diff

=item * L<DBIO::PostgreSQL::Introspect> - produces the models being compared

=item * L<DBIO::PostgreSQL::Diff::Schema>

=item * L<DBIO::PostgreSQL::Diff::Table>

=item * L<DBIO::PostgreSQL::Diff::Column>

=item * L<DBIO::PostgreSQL::Diff::View>

=item * L<DBIO::PostgreSQL::Diff::Type>

=item * L<DBIO::PostgreSQL::Diff::Index>

=item * L<DBIO::PostgreSQL::Diff::ForeignKey>

=item * L<DBIO::PostgreSQL::Diff::Function>

=item * L<DBIO::PostgreSQL::Diff::Trigger>

=item * L<DBIO::PostgreSQL::Diff::Policy>

=item * L<DBIO::PostgreSQL::Diff::Extension>

=item * L<DBIO::PostgreSQL::Diff::CaseOnly> - the rule for a name in two spellings

=item * L<DBIO::PostgreSQL::Diff::NoStatement> - the rule for an operation without a statement

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
