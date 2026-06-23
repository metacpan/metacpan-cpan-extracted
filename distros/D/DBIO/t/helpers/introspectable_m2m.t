use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;

{
  package #
    DBIO::Test::Schema::M2MUser;
  use base 'DBIO::Core';

  __PACKAGE__->table('m2m_user');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->has_many(
    user_roles => 'DBIO::Test::Schema::M2MUserRole' => 'user_id'
  );
  __PACKAGE__->many_to_many(roles => user_roles => 'role');

  __PACKAGE__->has_many(
    user_groups => 'DBIO::Test::Schema::M2MUserGroup' => 'user_id'
  );
  __PACKAGE__->many_to_many(
    groups => user_groups => 'group',
    { order_by => 'name' },
  );
}
{
  package #
    DBIO::Test::Schema::M2MRole;
  use base 'DBIO::Core';

  __PACKAGE__->table('m2m_role');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package #
    DBIO::Test::Schema::M2MUserRole;
  use base 'DBIO::Core';

  __PACKAGE__->table('m2m_user_role');
  __PACKAGE__->add_columns(
    user_id => { data_type => 'integer' },
    role_id => { data_type => 'integer' },
  );
  __PACKAGE__->belongs_to(user => 'DBIO::Test::Schema::M2MUser', 'user_id');
  __PACKAGE__->belongs_to(role => 'DBIO::Test::Schema::M2MRole', 'role_id');
}
{
  package #
    DBIO::Test::Schema::M2MGroup;
  use base 'DBIO::Core';

  __PACKAGE__->table('m2m_group');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package #
    DBIO::Test::Schema::M2MUserGroup;
  use base 'DBIO::Core';

  __PACKAGE__->table('m2m_user_group');
  __PACKAGE__->add_columns(
    user_id  => { data_type => 'integer' },
    group_id => { data_type => 'integer' },
  );
  __PACKAGE__->belongs_to(user  => 'DBIO::Test::Schema::M2MUser',  'user_id');
  __PACKAGE__->belongs_to(group => 'DBIO::Test::Schema::M2MGroup', 'group_id');
}

my $user_class = 'DBIO::Test::Schema::M2MUser';

subtest '_m2m_metadata accessor is installed' => sub {
  can_ok($user_class, '_m2m_metadata');
  my $store = $user_class->_m2m_metadata;
  is(ref $store, 'HASH', '_m2m_metadata returns a hashref');
};

subtest 'metadata for plain many_to_many (no attrs)' => sub {
  my $meta = $user_class->_m2m_metadata->{roles};
  is(ref $meta, 'HASH', 'entry for roles exists');

  is($meta->{accessor},         'roles',             'accessor');
  is($meta->{relation},         'user_roles',        'relation (bridge)');
  is($meta->{foreign_relation}, 'role',              'foreign_relation');
  is($meta->{rs_method},        'roles_rs',          'rs_method');
  is($meta->{add_method},       'add_to_roles',      'add_method');
  is($meta->{set_method},       'set_roles',         'set_method');
  is($meta->{remove_method},    'remove_from_roles', 'remove_method');

  ok(!exists $meta->{attrs}, 'attrs absent when no 4th arg was passed');
};

subtest 'metadata for many_to_many with attrs' => sub {
  my $meta = $user_class->_m2m_metadata->{groups};
  is(ref $meta, 'HASH', 'entry for groups exists');

  is($meta->{accessor},         'groups',             'accessor');
  is($meta->{relation},         'user_groups',        'relation (bridge)');
  is($meta->{foreign_relation}, 'group',              'foreign_relation');
  is($meta->{rs_method},        'groups_rs',          'rs_method');
  is($meta->{add_method},       'add_to_groups',      'add_method');
  is($meta->{set_method},       'set_groups',         'set_method');
  is($meta->{remove_method},    'remove_from_groups', 'remove_method');

  is(ref $meta->{attrs}, 'HASH',    'attrs stored as hashref');
  is($meta->{attrs}{order_by}, 'name', 'attrs preserve content');
};

subtest 'overwrite emits a warning' => sub {
  my @w;
  local $SIG{__WARN__} = sub { push @w, $_[0] };

  local $ENV{DBIO_OVERWRITE_HELPER_METHODS_OK} = 1;

  $user_class->many_to_many(roles => user_roles => 'role');

  ok(
    (grep { /Overwriting existing many-to-many metadata for 'roles'/ } @w),
    'redefining a many_to_many emits an overwrite warning'
  ) or diag explain \@w;
};

subtest 'metadata is per-class (not on the helper package)' => sub {
  my $foreign = \%DBIO::Test::Schema::M2MRole::;
  ok(
    !exists $foreign->{_m2m_metadata} || !keys %{$user_class->_m2m_metadata->{__no_such_key__} || {}},
    'sanity check',
  );
  my $user_meta = $user_class->_m2m_metadata;
  ok(exists $user_meta->{roles},  'roles on user class');
  ok(exists $user_meta->{groups}, 'groups on user class');
};

done_testing;
