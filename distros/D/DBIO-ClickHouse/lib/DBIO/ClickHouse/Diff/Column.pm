package DBIO::ClickHouse::Diff::Column;
# ABSTRACT: Diff operations for ClickHouse columns

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use Exporter 'import';

use DBIO::Diff::Op   ();
use DBIO::Diff::Compare qw(changed_fields column_change_lossy);
use DBIO::ClickHouse::DDL::Emit qw(
  column_def quote_ident
  alter_table_add_column alter_table_modify_column alter_table_drop_column
  alter_table_remove_default
);

our @EXPORT_OK = qw(changed_column norm_clickhouse_type is_nullable_type);

__PACKAGE__->mk_diff_accessors(qw/table_name column_name old_info new_info storage/);



sub norm_clickhouse_type {
  my ($type) = @_;
  return '' unless defined $type;
  $type =~ s/\s+/ /g;
  $type =~ s/\A\s+//;
  $type =~ s/\s+\z//;
  return $type;
}


sub changed_column {
  my ($old, $new) = @_;
  $old ||= {};
  $new ||= {};

  return () if _is_unmanaged_computed($old, $new);

  my @changed;
  push @changed, 'data_type'
    if defined $new->{data_type}
    && norm_clickhouse_type($old->{data_type}) ne norm_clickhouse_type($new->{data_type});

  push @changed, changed_fields($old, $new, scalar => ['default_value']);

  # Both sides are introspected from a server, so an undef default on the
  # target is "the schema declares none", not "the schema has no opinion":
  # the live default is removed (karr k43).
  push @changed, 'default_value'
    if !grep({ $_ eq 'default_value' } @changed) && _removes_default($old, $new);

  return @changed;
}


sub is_nullable_type {
  my ($type) = @_;
  return 0 unless defined $type;
  return norm_clickhouse_type($type) =~ /\A(?:LowCardinality\()?Nullable\(/ ? 1 : 0;
}

# The live column has a plain DEFAULT, the target none.
sub _removes_default {
  my ($old, $new) = @_;
  return defined $old->{default_value} && !defined $new->{default_value}
      && uc($old->{default_kind} // 'DEFAULT') eq 'DEFAULT' ? 1 : 0;
}

sub _is_unmanaged_computed {
  my ($old, $new) = @_;
  my $old_kind = uc($old->{default_kind} // 'DEFAULT');
  return 0 if $old_kind eq 'DEFAULT';
  return 0 if defined $new->{default_kind};
  return 1;
}


sub diff {
  my ($class, $source, $target, $source_tables, $target_tables, $storage) = @_;

  return $class->diff_nested($source, $target,
    index_by      => 'column_name',
    scope         => 'both',
    source_tables => $source_tables,
    target_tables => $target_tables,
    changed_when  => sub {
      my ($old, $new) = @_;
      scalar changed_column($old, $new);
    },
    on_new => sub {
      my ($table_name, $col_name, $new) = @_;
      $class->new(
        action      => 'add',
        table_name  => $table_name,
        column_name => $col_name,
        new_info    => $new,
        storage     => $storage,
      );
    },
    on_changed => sub {
      my ($table_name, $col_name, $old, $new) = @_;
      $class->new(
        action      => 'alter',
        table_name  => $table_name,
        column_name => $col_name,
        old_info    => $old,
        new_info    => $new,
        storage     => $storage,
      );
    },
    on_gone => sub {
      my ($table_name, $col_name, $old) = @_;
      $class->new(
        action      => 'drop',
        table_name  => $table_name,
        column_name => $col_name,
        old_info    => $old,
        storage     => $storage,
      );
    },
  );
}


sub as_sql {
  my ($self) = @_;

  my $if_guard = DBIO::Diff::Op::should_emit_if_exists($self->storage) ? 1 : 0;

  return alter_table_drop_column(
    table     => $self->table_name,
    name      => $self->column_name,
    if_exists => $if_guard,
  ) if $self->action eq 'drop';

  my $info = $self->new_info // {};
  my $def  = column_def(
    name    => $self->column_name,
    type    => ($info->{data_type} // 'String'),
    default => $info->{default_value}
  );

  return alter_table_add_column(
    table         => $self->table_name,
    definition    => $def,
    if_not_exists => $if_guard,
  ) if $self->action eq 'add';

  # A default the schema no longer declares goes first, so the old expression
  # is not checked against the new type; a type change follows as a statement
  # of its own (REMOVE DEFAULT takes no type beside it).
  if ($self->removes_default) {
    my @sql = alter_table_remove_default(table => $self->table_name, name => $self->column_name);
    push @sql, alter_table_modify_column(table => $self->table_name, definition => $def)
      if norm_clickhouse_type(($self->old_info // {})->{data_type})
         ne norm_clickhouse_type($info->{data_type});
    return join "\n", @sql;
  }

  # MODIFY COLUMN does not accept the flag: ClickHouse has no such guard
  # (t/38), and alter_table_modify_column in Emit croaks if the flag is
  # passed. The capability helper returns 1 here for the same storage, but
  # the alter_table_modify_column path ignores storage entirely -- that is
  # by design, not a leak.
  return alter_table_modify_column(table => $self->table_name, definition => $def);
}


sub removes_default {
  my ($self) = @_;
  return 0 unless $self->action eq 'alter';
  return _removes_default($self->old_info // {}, $self->new_info // {});
}


our %LOSSLESS_PAIRS;
{
  for my $ladder ([qw(int8 int16 int32 int64 int128 int256)],
                  [qw(uint8 uint16 uint32 uint64 uint128 uint256)]) {
    for my $from (0 .. $#$ladder - 1) {
      $LOSSLESS_PAIRS{"$ladder->[$from]->$ladder->[$_]"} = 1 for $from + 1 .. $#$ladder;
    }
  }
  $LOSSLESS_PAIRS{'date->date32'}       = 1;
  $LOSSLESS_PAIRS{'datetime->datetime64'} = 1;
  $LOSSLESS_PAIRS{'enum8->enum16'}      = 1;
}

my %DECIMAL_PRECISION = (decimal32 => 9, decimal64 => 18, decimal128 => 38, decimal256 => 76);

# The parts of a native type string: wrappers off, base name, the parameters.
sub _parse_type {
  my ($type) = @_;
  my $t = norm_clickhouse_type($type);
  my %p = (nullable => 0, raw => $t);
  while ($t =~ /\A(LowCardinality|Nullable)\((.*)\)\z/s) {
    $p{ lc $1 } = 1;
    $t = $2;
  }
  $p{inner} = $t;
  my ($name, $args) = $t =~ /\A(\w+)(?:\((.*)\))?\z/s ? ($1, $2) : ($t, undef);
  @p{qw(name args)} = (lc $name, $args);
  return \%p;
}

# The info as column_change_lossy reads it, or undef for a type whose
# parameters are not understood (they must then be equal).
sub _sized_info {
  my ($p) = @_;
  my ($name, $args) = @{$p}{qw(name args)};
  return { data_type => $name } unless defined $args;

  if ($name eq 'decimal' && $args =~ /\A\s*(\d+)\s*,\s*(\d+)\s*\z/) {
    return { data_type => 'decimal', size => [ $1, $2 ] };
  }
  if ($DECIMAL_PRECISION{$name} && $args =~ /\A\s*(\d+)\s*\z/) {
    return { data_type => 'decimal', size => [ $DECIMAL_PRECISION{$name}, $1 ] };
  }
  if ($name eq 'fixedstring' && $args =~ /\A\s*(\d+)\s*\z/) {
    return { data_type => $name, size => $1 };
  }
  if ($name eq 'datetime64' && $args =~ /\A\s*(\d+)\s*(?:,\s*'((?:[^'\\]|\\.)*)')?\s*\z/) {
    return { data_type => $name, size => $1, tz => $2 // '' };
  }
  if ($name eq 'datetime' && $args =~ /\A\s*'((?:[^'\\]|\\.)*)'\s*\z/) {
    return { data_type => $name, tz => $1 };
  }
  return undef;
}

sub _enum_elements {
  my ($args) = @_;
  my @el;
  while ($args =~ /'((?:[^'\\]|\\.)*)'\s*=\s*(-?\d+)/g) { push @el, [ $1, $2 ] }
  return \@el;
}


sub lossy {
  my ($self) = @_;
  return 0 unless $self->action eq 'alter';
  my ($old, $new) = ($self->old_info // {}, $self->new_info // {});

  # a target without a type prescribes none
  return 0 unless defined $new->{data_type};
  return 0 if norm_clickhouse_type($old->{data_type}) eq norm_clickhouse_type($new->{data_type});

  my ($po, $pn) = (_parse_type($old->{data_type}), _parse_type($new->{data_type}));
  return 1 if $po->{nullable} && !$pn->{nullable};

  # the same base type with the same spelling: only the wrappers changed
  return 0 if $po->{inner} eq $pn->{inner};

  if ($po->{name} =~ /\Aenum(?:8|16)\z/ || $pn->{name} =~ /\Aenum(?:8|16)\z/) {
    return 1 unless $po->{name} =~ /\Aenum(?:8|16)\z/ && $pn->{name} =~ /\Aenum(?:8|16)\z/;
    return 1 if $po->{name} eq 'enum16' && $pn->{name} eq 'enum8';
    my @was = @{ _enum_elements($po->{args} // '') };
    my %now = map { ($_->[0] => $_->[1]) } @{ _enum_elements($pn->{args} // '') };
    return 1 unless @was;
    return 1 if grep { !defined $now{ $_->[0] } || $now{ $_->[0] } != $_->[1] } @was;
    return 0;
  }

  my ($io, $in) = (_sized_info($po), _sized_info($pn));
  # compound types and the like: only a change of wrappers is known to be safe
  return 1 unless $io && $in;

  if ($io->{data_type} =~ /\Adatetime(?:64)?\z/ && $in->{data_type} =~ /\Adatetime(?:64)?\z/) {
    return 1 if ($io->{tz} // '') ne ($in->{tz} // '');
  }

  return column_change_lossy($io, $in, \%LOSSLESS_PAIRS) ? 1 : 0;
}


sub needs_row_check {
  my ($self) = @_;
  return 0 unless $self->action eq 'add';
  my $info = $self->new_info // {};
  return 0 if defined $info->{default_value} || defined $info->{default_kind};
  return is_nullable_type($info->{data_type}) ? 0 : 1;
}


sub row_check_sql {
  my ($self) = @_;
  return sprintf 'SELECT 1 FROM %s LIMIT 1', quote_ident($self->table_name);
}


sub needs_null_check {
  my ($self) = @_;
  return 0 unless $self->action eq 'alter';
  return is_nullable_type(($self->old_info // {})->{data_type})
      && !is_nullable_type(($self->new_info // {})->{data_type}) ? 1 : 0;
}


sub null_check_sql {
  my ($self) = @_;
  return sprintf 'SELECT count() FROM %s WHERE %s IS NULL',
    quote_ident($self->table_name), quote_ident($self->column_name);
}


sub summary {
  my ($self) = @_;
  my $type = $self->new_info ? sprintf(' (%s)', $self->new_info->{data_type} // '') : '';
  return sprintf '  %scolumn: %s.%s%s',
    $self->summary_prefix, $self->table_name, $self->column_name, $type;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Diff::Column - Diff operations for ClickHouse columns

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Column-level diff operations for ClickHouse:
C<ALTER TABLE ... ADD COLUMN>, C<ALTER TABLE ... DROP COLUMN> and
C<ALTER TABLE ... MODIFY COLUMN>.

Columns of a brand-new table are emitted inline by
L<DBIO::ClickHouse::Diff::Table> (a ClickHouse table cannot be built up from
nothing with C<ADD COLUMN> -- it needs its engine and sorting key at C<CREATE>
time), so this module only ever sees tables present in both models.

=head2 MODIFY COLUMN, not a rebuild

C<MODIFY COLUMN> covers almost every type change: widening an integer,
C<String> to C<FixedString>, adding or removing C<Nullable>, changing a
C<Decimal> scale. ClickHouse rewrites the affected parts as an asynchronous
B<mutation> -- the statement returns before the data has been converted, and
C<system.mutations> is where you watch it finish. So an C<upgrade> that returns
successfully means the change was I<accepted>, not that it is I<done>.

The changes C<MODIFY COLUMN> cannot make are the ones that touch the sorting
key, the partition key or the engine. Those never reach this module: they are
refused up front by
L<DBIO::ClickHouse::Diff::Table/check_rebuild_required>.

=head2 Nullability is not a column property here

There is no C<SET NOT NULL> / C<DROP NOT NULL> to emit. ClickHouse columns are
NOT NULL by default and nullability lives inside the type (C<Nullable(T)>), so
a nullability change I<is> a type change and comes out as a single
C<MODIFY COLUMN>. The model's C<not_null> field is derived from the type
string by L<DBIO::ClickHouse::Introspect::Columns> and is deliberately not
compared -- it cannot differ unless C<data_type> already did, and comparing it
would only produce a second, redundant operation.

=head2 Nullable to NOT NULL is the one change the data can break

A C<MODIFY COLUMN> from C<Nullable(T)> to a non-nullable type fails in the
background mutation as soon as one part holds a NULL -- and by then the
metadata is already switched: the column is unreadable, every later mutation
on the table hangs behind the broken one, and the NULLs can no longer be
counted. The diff itself sees no data and renders the statement
unchanged, so as a dry run (C<as_sql>, C<summary>) it stays data-free. Such an
op instead answers L</needs_null_check> and renders its precondition with
L</null_check_sql>; L<DBIO::ClickHouse::Deploy/_check_before_apply> runs it
B<before the first statement> of the plan and refuses when it finds NULL rows.
Besides, such a change is L</lossy>, so the plan runs only with
C<allow_destructive>.

=head2 What is compared, and what is left alone

Compared: C<data_type> (the native ClickHouse type string) and
C<default_value> (the raw default expression).

C<changed_column> carries one rule beyond core's desired-state contract: both
sides here are introspected from a server, so a target without a default
means "declared none", and a live plain C<DEFAULT> is a change.

Not compared, on purpose:

=over 4

=item * C<comment> -- L<DBIO::ClickHouse::DDL> never emits column comments, so
the desired side always reports none. Comparing it would drop every comment on
the live database at the first upgrade.

=item * C<compression_codec> -- same reason. A hand-tuned C<CODEC(ZSTD(3))> is
not something a portable schema prescribes, and clearing it silently would cost
disk on every part written afterwards.

=item * C<position> -- ClickHouse can reorder with
C<MODIFY COLUMN ... AFTER>, but column order only affects C<SELECT *>, and a
reorder rewrites metadata for every part. Not worth an automatic mutation.

=back

=head2 Type comparison is case-preserving

Core's L<DBIO::Diff::Compare/norm_type> upper-cases before comparing, which is
right for engines whose type strings are pure syntax. ClickHouse type strings
carry B<string literals>: C<Enum8('draft' = 1, 'live' = 2)>,
C<DateTime64(3, 'UTC')>. Upper-casing those would make C<'draft'> and
C<'Draft'> the same type and silently swallow an enum rename. So
L</norm_clickhouse_type> collapses whitespace -- the only thing the server
varies -- and leaves case alone.

=head2 Known phantom-diff sources

Both sides of a test-deploy-and-compare diff are introspected from a real
server, so the native type strings are rendered by the same code and compare
cleanly. One case is worth knowing about anyway:

=over 4

=item * B<Do not hand-build the target from C<column_info>.> The DDL layer
collapses the whole C<varchar> / C<char> / C<text> / C<json> family onto
C<String>, and introspection can only report one of them back. A target model
carrying portable DBIO type names rather than native ClickHouse ones will
differ from the live side on every string column, forever. Build the target by
deploying and introspecting, which is what L<DBIO::ClickHouse::Deploy> does.

=back

Bare C<Date> / C<DateTime> used to belong here: the DDL layer lower-cased
C<data_type> before its type-map lookup, so a column declared
C<< data_type => 'Date' >> deployed as C<Date32> and reappeared as a
C<MODIFY COLUMN> on every run. It now passes an exact native spelling through
untouched, so a live C<Date> column and a schema asking for C<Date> agree. A
C<Date>-against-C<Date32> diff is a genuine type change today, and converges
after one apply.

=head1 ATTRIBUTES

=head2 lossy_pairs

    my %pairs = %DBIO::ClickHouse::Diff::Column::LOSSLESS_PAIRS;

The changes of the base type that C<MODIFY COLUMN> carries out without loss, as
the C<< old->new >> keys (lower case) L<DBIO::Diff::Compare/column_change_lossy>
reads. The type is taken without its C<Nullable(...)> and
C<LowCardinality(...)> wrappers and without its parameters:

=over 4

=item * C<Int8> E<lt> C<Int16> E<lt> C<Int32> E<lt> C<Int64> E<lt> C<Int128>
E<lt> C<Int256>, and the same ladder of the C<UInt> types: a wider integer of
the same signedness holds every value of the narrower one.

=item * C<Date> to C<Date32> (the range of C<Date> lies within that of
C<Date32>) and C<DateTime> to C<DateTime64> (whole seconds are exact).

=back

Beyond the pairs, a type that stays the same is lossless when its parameters
only grow (L<DBIO::Diff::Compare/column_change_lossy>): C<Decimal(P, S)> with
the same scale and a larger precision (C<Decimal32> to C<Decimal256> are read as
C<Decimal(9|18|38|76, S)>), C<FixedString(N)> with a larger C<N>,
C<DateTime64(P)> with a larger precision and the same time zone, and
C<Enum8>/C<Enum16> whose elements are the old ones with the same values and more
behind them (C<Enum8> to C<Enum16> included). C<LowCardinality(...)> around the
same type is no change of value, and a column that gains C<Nullable(...)> keeps
every value.

Every other change is lossy, in doubt it is: C<Float32> to C<Float64> alters the
decimal reading of a value, an integer to a float or a signed to an unsigned
type rewrites it, C<String> to C<FixedString> and back, C<Nullable(T)> to a
non-nullable type (the NULLs become the zero value of the type) and every
change inside C<Array>, C<Tuple>, C<Map> and the other compound types.

Source: L<https://clickhouse.com/docs/sql-reference/statements/alter/column#modify-column>
(a changed type is converted as by the C<toType> functions).

=head1 METHODS

=head2 norm_clickhouse_type

    my $t = norm_clickhouse_type('Decimal(10,  2)');   # 'Decimal(10, 2)'

Normalizes a native ClickHouse type string for comparison: collapses runs of
whitespace to a single space and trims the ends. C<undef> becomes the empty
string. Case is B<preserved>; see L</Type comparison is case-preserving>.

=head2 changed_column

    my @changed = changed_column($old_info, $new_info);

Returns the list of column fields that differ, or the empty list when the
column is unchanged. C<data_type> is compared with L</norm_clickhouse_type>,
C<default_value> through core's L<DBIO::Diff::Compare/changed_fields>, plus the
removal of a live plain C<DEFAULT> the target no longer declares.

A column whose B<live> side is C<MATERIALIZED>, C<ALIAS> or C<EPHEMERAL> and
whose target side prescribes no kind of its own is reported as unchanged. Such
a column is computed, not stored as given, and this driver cannot render those
clauses from a desired-state model; emitting a bare C<MODIFY COLUMN> for it
would strip the expression and turn a derived column into an empty one.

=head2 is_nullable_type

    is_nullable_type('LowCardinality(Nullable(String))');   # true

True when the native type string is nullable at the top level, i.e.
C<Nullable(T)>, optionally wrapped in C<LowCardinality(...)>. Nullable inside
C<Array>, C<Tuple> or C<Map> is not top-level and not reported.

=head2 diff

    my @ops = DBIO::ClickHouse::Diff::Column->diff(
      $source_columns, $target_columns,
      $source_tables,  $target_tables,
      $storage,                                # optional, drives IF EXISTS
    );

Compares the C<columns> sections of two models, scoped to tables present in
both C<tables> sections. Members are keyed by C<column_name> (the model stores
them as an ordered arrayref). C<$storage> threads through to the
constructed ops; see L</as_sql>.

=head2 as_sql

Renders one C<ALTER TABLE> statement. The column definition itself goes
through L<DBIO::ClickHouse::DDL::Emit/column_def>, so an added column is
spelled exactly as the same column would be in a fresh C<CREATE TABLE>.

C<MODIFY COLUMN> restates the type and, when the target prescribes one, the
default. A target that declares no default while the live column has a plain
C<DEFAULT> gets it removed: ClickHouse keeps the old expression when the clause
is absent, so the removal is a statement of its own, C<MODIFY COLUMN ... REMOVE
DEFAULT>, emitted before a type change. A computed live column
(C<MATERIALIZED>, C<ALIAS>, C<EPHEMERAL>) is still left alone.

=head2 removes_default

True for an C<alter> whose live column carries a plain C<DEFAULT> the target
does not: rendered as C<MODIFY COLUMN ... REMOVE DEFAULT>
(L<DBIO::ClickHouse::DDL::Emit/alter_table_remove_default>). The rows keep what
they were written with.

=head2 lossy

True for an C<alter> that can alter or lose stored values, so that
L<DBIO::Deploy::Base/apply> runs it only with C<allow_destructive>.
The two C<data_type> strings are taken apart -- C<Nullable(...)> and
C<LowCardinality(...)> off, base type and parameters read -- and the base types
are judged by L<DBIO::Diff::Compare/column_change_lossy> with the pairs of
L</lossy_pairs>. Besides:

=over 4

=item * C<Nullable(T)> to a non-nullable type is lossy (NULL becomes the zero
value of the type); a column that gains C<Nullable(...)> is not;

=item * a time zone that differs (C<DateTime>, C<DateTime64>) is lossy;

=item * an C<Enum> whose elements are not the old ones, same names with the same
values, with more behind them is lossy;

=item * a type whose parameters are not understood (C<Array>, C<Tuple>, C<Map>,
...) is lossy unless it is spelled the same.

=back

A change of the default alone keeps the type, and with it every value: not lossy.
Other actions are not lossy.

=head2 needs_row_check

True for an C<add> of a column that is not C<Nullable> and has no default of
its own: the server would fill the rows the table already holds with the type's
zero value (C<''>, C<0>), a value nobody wrote. L<DBIO::ClickHouse::Deploy/_check_before_apply>
asks L</row_check_sql> before the first statement and refuses when the table
holds rows. A column with a default (any kind) or a C<Nullable> one needs no
check.

=head2 row_check_sql

The precondition of a L</needs_row_check> op: a read-only probe for one row of
the table. The diff never runs it.

=head2 needs_null_check

True for a C<MODIFY COLUMN> that turns a nullable column into a non-nullable
one -- the only op whose success depends on the data. See
L</Nullable to NOT NULL is the one change the data can break>.

=head2 null_check_sql

The precondition of a L</needs_null_check> op: a C<SELECT count()> of the rows
whose column is NULL. Read-only; the diff never runs it.

=head2 summary

One indented line naming the column, its table, the target type, and whether
it is added (C<+>), dropped (C<->) or modified (C<~>).

=head2 HOW IT LINKS INTO PARTIAL-FAILURE REAPPLY

C<ADD COLUMN> and C<DROP COLUMN> each accept a guard from
L<DBIO::ClickHouse::DDL::Emit>; the flag is populated here from
L<DBIO::Diff::Op/should_emit_if_exists> on the op's stashed C<storage>, so a
re-run after a partial failure becomes a no-op rather than erroring on the
already-applied statement. Two pitfalls are deliberate, not bugs:

=over 4

=item * C<MODIFY COLUMN> never carries a guard: t/38 confirms ClickHouse has
no C<ALTER TABLE ... MODIFY COLUMN IF [NOT] EXISTS> form, so a re-apply
genuinely has to repeat the C<MODIFY>. The applier does not silently skip the
step -- the danger is the opposite, that a type change silently survives.

=item * C<ALTER TABLE ... ADD COLUMN IF NOT EXISTS> swallows a column that
already exists with a B<different> type as a silent no-op. The flag here is
only set when the F12 capability is on; the actual type-change safety net on
a real type shift is the C<MODIFY COLUMN> that this same diff will emit
afterwards.

=back

=head1 SEE ALSO

=over 4

=item * L<DBIO::ClickHouse::Diff> - the orchestrator that drives this

=item * L<DBIO::ClickHouse::Diff::Table> - refuses the changes MODIFY cannot make

=item * L<DBIO::ClickHouse::DDL::Emit> - the statement templates rendered here

=item * L<DBIO::ClickHouse::Introspect::Columns> - produces the model section

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
