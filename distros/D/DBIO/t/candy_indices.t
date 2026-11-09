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
my $idxs   = $source->{_index_declarations};

ok $idxs, '_index_declarations populated by indices()';
is scalar(@$idxs), 2, 'two indexes registered';

my %by_name = map { $_->{name} => $_ } @$idxs;
is_deeply $by_name{name_idx}{columns}, ['name'],
  'scalar field promoted to single-element arrayref';
is_deeply $by_name{name_city_idx}{columns}, ['name', 'city'],
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

is scalar(@{ TestIdx::Result::HashForm->result_source_instance->{_index_declarations} }),
  1, 'hashref form accepted';

# --- Multiple calls accumulate ---

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
is_deeply [ map $_->{name}, $multi_src->index_declarations ],
  [qw(idx_a idx_b)],
  'separate indices() calls accumulate in index_declarations';

# --- No derived method on the class ---

for my $class (qw(TestIdx::Result::Multi TestIdx::Result::Artist)) {
  ok !$class->can('sqlt_deploy_hook'),
    "$class: no sqlt_deploy_hook derived from the declarations";
  ok !$class->can('pg_indexes'),
    "$class: no pg_indexes derived from the declarations";
}

# --- The canonical declaration carries the shape a driver reads ---

{
  my %decl = map { $_->{name} => $_ }
    TestIdx::Result::Artist->result_source_instance->index_declarations;
  is_deeply $decl{name_idx}{columns}, ['name'],
    'declaration for scalar field';
  is_deeply $decl{name_city_idx}{columns}, ['name', 'city'],
    'declaration for compound index';
}

# indices is inherited from DBIO::ResultSourceProxy, so it stays
# available as a class method even after Candy's namespace::clean runs.
ok(TestIdx::Result::Artist->can('indices'),
  'indices class method remains available after sugar cleanup');

done_testing();
