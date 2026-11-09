use strict;
use warnings;
use Test::More;

# --- Vanilla usage: class method without any sugar layer ---

{
  package TestVanillaIdx::Result::Artist;
  use base 'DBIO::Core';

  __PACKAGE__->table('artists');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
    city => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');

  __PACKAGE__->indices(
    name_idx      => 'name',
    name_city_idx => ['name', 'city'],
  );
}

my $source = TestVanillaIdx::Result::Artist->result_source_instance;
my $idxs   = $source->{_index_declarations};

ok $idxs, 'indices() class method populates _index_declarations';
is scalar(@$idxs), 2, 'two indexes registered';

my %by_name = map { $_->{name} => $_ } @$idxs;
is_deeply $by_name{name_idx}{columns}, ['name'],
  'scalar field promoted to arrayref';
is_deeply $by_name{name_city_idx}{columns}, ['name', 'city'],
  'arrayref fields preserved';

# --- Hashref form works ---

{
  package TestVanillaIdx::Result::HashForm;
  use base 'DBIO::Core';

  __PACKAGE__->table('hf');
  __PACKAGE__->add_columns(id => { data_type => 'integer' }, a => { data_type => 'text' });
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->indices({ a_idx => 'a' });
}

is scalar(@{ TestVanillaIdx::Result::HashForm->result_source_instance->{_index_declarations} }),
  1, 'hashref form accepted on class method';

# --- The declaration derives no method on the class ---

ok !TestVanillaIdx::Result::Artist->can('sqlt_deploy_hook'),
  'indices() installs no sqlt_deploy_hook on the class';
ok !TestVanillaIdx::Result::Artist->can('pg_indexes'),
  'indices() installs no pg_indexes on the class';

# A further call accumulates in the declaration list

TestVanillaIdx::Result::Artist->indices(extra_idx => 'city');
is_deeply [ map $_->{name}, $source->index_declarations ],
  [qw(name_city_idx name_idx extra_idx)],
  'second call accumulates after the first (names of one call sorted)';

done_testing();
