package # hide from PAUSE
    RestTest::Schema::Result::Producer;

use base 'DBIx::Class::Core';

__PACKAGE__->table('producer');
__PACKAGE__->add_columns(
  'producerid' => {
    data_type => 'integer',
    is_auto_increment => 1
  },
  'name' => {
    data_type => 'varchar',
    size      => 100,
	default_value => 'fred'
  },
);
__PACKAGE__->set_primary_key('producerid');
__PACKAGE__->add_unique_constraint(prod_name => [ qw/name/ ]);

1;
