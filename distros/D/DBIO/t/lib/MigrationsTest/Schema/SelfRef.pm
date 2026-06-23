package # hide from PAUSE
    MigrationsTest::Schema::SelfRef;

use warnings;
use strict;

use base qw/MigrationsTest::BaseResult/;

__PACKAGE__->table('self_ref');
__PACKAGE__->add_columns(
  'id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'name' => {
    data_type => 'varchar',
    size      => 100,
  },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many( aliases => 'MigrationsTest::Schema::SelfRefAlias' => 'self_ref' );

1;
