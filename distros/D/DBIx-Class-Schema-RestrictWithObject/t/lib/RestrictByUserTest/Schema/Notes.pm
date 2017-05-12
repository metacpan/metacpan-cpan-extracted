package # hide from PAUSE
    RestrictByUserTest::Schema::Notes;

use base 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('notes_test');
__PACKAGE__->add_columns(
  'id' => {
    data_type => 'int',
    is_nullable => 0,
    is_auto_increment => 1,
  },
  'user_id' => {
    data_type => 'int',
  },
  'name' => {
    data_type => 'varchar',
    size      => 100,
  }
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to("user", "Users", { id => "user_id" });

1;
