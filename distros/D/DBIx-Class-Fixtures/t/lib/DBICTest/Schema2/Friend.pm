package # hide from PAUSE 
    DBICTest::Schema2::Friend;

use base 'DBIx::Class::Core';

__PACKAGE__->table('friend');
__PACKAGE__->add_columns(
  'friendid' => {
    data_type => 'integer',
    is_auto_increment => 1
  },
  'name' => {
    data_type => 'varchar',
    size      => 100,
  },
);
__PACKAGE__->set_primary_key('friendid');
__PACKAGE__->add_unique_constraint(prod_name => [ qw/name/ ]);

1;
