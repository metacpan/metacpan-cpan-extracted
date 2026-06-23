package My::Schema::Result::Book;

use DBIO;

__PACKAGE__->table('books');

__PACKAGE__->add_columns(
  id        => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
  title     => { data_type => 'varchar', is_nullable => 0 },
  author_id => { data_type => 'integer', is_nullable => 0 },
  price     => { data_type => 'decimal', is_nullable => 1 },
  in_print  => { data_type => 'boolean', is_nullable => 1, default_value => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
  author => 'My::Schema::Result::Author',
  { 'foreign.id' => 'self.author_id' },
);

1;
