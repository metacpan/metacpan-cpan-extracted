use strict;
use warnings;
use Test::More;

# --- Basic registration ---

{
  package TestIdx::Result::Artist;
  use DBIO::Candy;

  table 'artists';
  primary_column id   => { data_type => 'integer' };
  column         name => { data_type => 'text' };
  column         city => { data_type => 'text' };

  indices(
    name_idx      => 'name',
    name_city_idx => ['name', 'city'],
  );
}

my $source = TestIdx::Result::Artist->result_source_instance;
my $idxs   = $source->{_cake_indexes};

ok $idxs, '_cake_indexes populated by indices()';
is scalar(@$idxs), 2, 'two indexes registered';

my %by_name = map { $_->{name} => $_ } @$idxs;
is_deeply $by_name{name_idx}{fields}, ['name'],
  'scalar field promoted to single-element arrayref';
is_deeply $by_name{name_city_idx}{fields}, ['name', 'city'],
  'arrayref fields preserved';

# --- Hashref form is equivalent ---

{
  package TestIdx::Result::HashForm;
  use DBIO::Candy;

  table 'hf';
  primary_column id => { data_type => 'integer' };
  column         a  => { data_type => 'text' };

  indices({ a_idx => 'a' });
}

is scalar(@{ TestIdx::Result::HashForm->result_source_instance->{_cake_indexes} }),
  1, 'hashref form accepted';

# --- Multiple calls accumulate, hooks installed once ---

{
  package TestIdx::Result::Multi;
  use DBIO::Candy;

  table 'multi';
  primary_column id => { data_type => 'integer' };
  column         a  => { data_type => 'text' };
  column         b  => { data_type => 'text' };

  indices(idx_a => 'a');
  indices(idx_b => 'b');
}

my $multi_src = TestIdx::Result::Multi->result_source_instance;
is scalar(@{ $multi_src->{_cake_indexes} }), 2,
  'separate indices() calls accumulate';
ok $multi_src->{_cake_hook_installed},
  'sqlt_deploy_hook flag set';
ok $multi_src->{_cake_pg_indexes_installed},
  'pg_indexes flag set';

ok(TestIdx::Result::Multi->can('sqlt_deploy_hook'),
  'sqlt_deploy_hook installed on class');
ok(TestIdx::Result::Multi->can('pg_indexes'),
  'pg_indexes installed on class');

# --- sqlt_deploy_hook actually pushes into the SQLT table ---

{
  package FakeSQLTTable;
  sub new { bless { added => [] }, shift }
  sub add_index { my $self = shift; push @{ $self->{added} }, { @_ } }
  sub added { $_[0]->{added} }
}

my $fake = FakeSQLTTable->new;
TestIdx::Result::Artist->sqlt_deploy_hook($fake);

is scalar(@{ $fake->added }), 2, 'two add_index calls from hook';
my %added = map { $_->{name} => $_ } @{ $fake->added };
is_deeply $added{name_idx}{fields}, ['name'], 'name_idx fields passed through';
is_deeply $added{name_city_idx}{fields}, ['name', 'city'],
  'name_city_idx fields passed through';

# --- pg_indexes returns the right shape for native PG deploy ---

my $pg = TestIdx::Result::Artist->pg_indexes;
is_deeply $pg->{name_idx},      { columns => ['name'] },
  'pg_indexes entry for scalar field';
is_deeply $pg->{name_city_idx}, { columns => ['name', 'city'] },
  'pg_indexes entry for compound index';

# indices is inherited from DBIO::ResultSourceProxy, so it stays
# available as a class method even after Candy's namespace::clean runs.
ok(TestIdx::Result::Artist->can('indices'),
  'indices class method remains available after sugar cleanup');

done_testing();
