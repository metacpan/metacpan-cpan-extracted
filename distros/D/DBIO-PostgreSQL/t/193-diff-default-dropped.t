use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Diff::Column;

# karr k150, case diff-default-removed of core's Diff list (ADR 0060).
#
# WHY it exists: the column diff compared through DBIO::Diff::Compare, whose
# desired-state rule skips a field the target leaves undef. Both models of this
# driver are read from a catalog, so an undef default_value in the target is a
# column that has none, not a column that prescribes nothing. A declaration
# that dropped a default left the database's default in place: the upgrade
# wrote no statement and the next diff was empty too, so the drift was silent.

my $tables = { 'public.t' => { schema_name => 'public', table_name => 't' } };

sub col {
  my (%c) = @_;
  return {
    column_name   => $c{name} // 'c',
    data_type     => 'character varying(10)',
    not_null      => 0,
    default_value => $c{default},
    ( defined $c{generated} ? (generated => $c{generated}) : () ),
  };
}

sub sql {
  my ($from, $to) = @_;
  return join "\n", map { $_->as_sql } DBIO::PostgreSQL::Diff::Column->diff(
    { 'public.t' => [ $from ] }, { 'public.t' => [ $to ] }, $tables, $tables,
  );
}

is sql(col(default => q{'x'::character varying}), col()),
  'ALTER TABLE public.t ALTER COLUMN c DROP DEFAULT;',
  'a default the target does not have is dropped';

is sql(col(default => q{'x'::character varying}), col(default => q{'x'::character varying})),
  '', 'the same default is no change';

is sql(col(), col(default => q{'y'::character varying})),
  q{ALTER TABLE public.t ALTER COLUMN c SET DEFAULT 'y'::character varying;},
  'a default the database lacks is set';

done_testing;
