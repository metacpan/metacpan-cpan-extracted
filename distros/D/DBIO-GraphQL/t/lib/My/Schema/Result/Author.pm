package My::Schema::Result::Author;

use DBIO;

__PACKAGE__->table('authors');

__PACKAGE__->add_columns(
  id     => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
  name   => { data_type => 'varchar', is_nullable => 0 },
  email  => { data_type => 'varchar', is_nullable => 1 },
  rating => { data_type => 'float',   is_nullable => 1 },
  active => { data_type => 'boolean', is_nullable => 1, default_value => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint(unique_email => ['email']);

__PACKAGE__->has_many(
  books => 'My::Schema::Result::Book',
  { 'foreign.author_id' => 'self.id' },
);

1;
