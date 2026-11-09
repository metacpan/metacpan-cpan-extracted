use strict;
use warnings;

use Test::More;

use DBIO::PostgreSQL::Diff;

# Offline counterpart of t/134 (karr k121): the diff reads the model. The
# copies of a partitioned table's index and trigger are not in the model (the
# introspection leaves them out), so a model that has the parent's object and
# no copy at the partition yields operations at the parent only.
#
# WHAT IT ASSERTS: with the parent's index and trigger new in the target and
# the partition carrying none in either model, no operation names the
# partition; and an index of the partition's own is still an operation of it.
# It cannot show the catalog read (that is t/134); it pins that the diff does
# not invent objects at a partition.

sub table {
  my ($name, %extra) = @_;
  return {
    schema_name => 'public', table_name => $name, kind => 'table',
    %extra,
  };
}

sub index_of {
  my ($table, $name) = @_;
  return { schema_name => 'public', table_name => $table, index_name => $name,
    access_method => 'btree', is_unique => 0, is_primary => 0, is_valid => 1,
    definition => "CREATE INDEX $name ON public.$table USING btree (v)",
    columns => ['v'], include_columns => [], storage_params => {},
    opclasses => {}, sort_options => {}, referenced_by => [] };
}

sub model {
  my (%o) = @_;
  return {
    schemas => { public => { schema_name => 'public' } },
    extensions => {}, types => {}, functions => {}, policies => {},
    sequences => {}, foreign_keys => {}, check_constraints => {}, triggers => {},
    tables => {
      'public.p'  => table('p',  kind => 'partitioned_table'),
      'public.p1' => table('p1', partition_of => 'public.p'),
    },
    columns => { 'public.p' => [], 'public.p1' => [] },
    indexes => $o{indexes} || {},
  };
}

my $source = model();
my $target = model(indexes => { 'public.p' => { p_v_idx => index_of('p', 'p_v_idx') } });

my $diff = eval { DBIO::PostgreSQL::Diff->new(source => $source, target => $target) };
my $sql = eval { join "\n", map { $_->as_sql } @{ $diff->operations } };
ok(defined $sql, 'the diff is built') or diag $@;
like($sql, qr/CREATE INDEX p_v_idx ON public\.p /, 'the index is created at the partitioned table');
unlike($sql, qr/public\.p1/, '... and nothing is written at the partition');

my $own = model(indexes => { 'public.p1' => { p1_own => index_of('p1', 'p1_own') } });
$sql = eval { join "\n", map { $_->as_sql } @{ DBIO::PostgreSQL::Diff->new(source => $source, target => $own)->operations } };
like($sql, qr/CREATE INDEX p1_own ON public\.p1 /, "an index of the partition's own is created");

done_testing;
