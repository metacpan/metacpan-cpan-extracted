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
my $idxs   = $source->{_cake_indexes};

ok $idxs, 'indices() class method populates _cake_indexes';
is scalar(@$idxs), 2, 'two indexes registered';

my %by_name = map { $_->{name} => $_ } @$idxs;
is_deeply $by_name{name_idx}{fields}, ['name'],
  'scalar field promoted to arrayref';
is_deeply $by_name{name_city_idx}{fields}, ['name', 'city'],
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

is scalar(@{ TestVanillaIdx::Result::HashForm->result_source_instance->{_cake_indexes} }),
  1, 'hashref form accepted on class method';

# --- Hooks installed, idempotent ---

ok(TestVanillaIdx::Result::Artist->can('sqlt_deploy_hook'),
  'sqlt_deploy_hook installed on class');
ok(TestVanillaIdx::Result::Artist->can('pg_indexes'),
  'pg_indexes installed on class');
ok $source->{_cake_hook_installed},   'sqlt hook flag set';
ok $source->{_cake_pg_indexes_installed}, 'pg_indexes flag set';

# Second call should not re-install hooks (idempotent)
TestVanillaIdx::Result::Artist->indices(extra_idx => 'city');
is scalar(@{ $source->{_cake_indexes} }), 3, 'second call accumulates';

# --- sqlt_deploy_hook pushes into fake SQLT table ---

{
  package FakeSQLTTable;
  sub new { bless { added => [] }, shift }
  sub add_index { my $self = shift; push @{ $self->{added} }, { @_ } }
  sub added { $_[0]->{added} }
}

my $fake = FakeSQLTTable->new;
TestVanillaIdx::Result::Artist->sqlt_deploy_hook($fake);
is scalar(@{ $fake->added }), 3, 'hook fired add_index three times';

# --- pg_indexes returns the correct shape ---

my $pg = TestVanillaIdx::Result::Artist->pg_indexes;
is_deeply $pg->{name_idx},      { columns => ['name'] },         'pg scalar';
is_deeply $pg->{name_city_idx}, { columns => ['name', 'city'] }, 'pg compound';

done_testing();
