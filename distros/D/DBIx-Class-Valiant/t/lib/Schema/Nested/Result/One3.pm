package Schema::Nested::Result::One3;

use base 'Schema::Result';

__PACKAGE__->table("one");


__PACKAGE__->add_columns(
  one_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
  value => { data_type => 'varchar', is_nullable => 0, size => 48 },
);

__PACKAGE__->set_primary_key("one_id");

__PACKAGE__->belongs_to(
  oneone =>
  'Schema::Nested::Result::OneOne2',
  { 'foreign.id' => 'self.one_id' },
);

__PACKAGE__->might_have(
  might =>
  'Schema::Nested::Result::Might3',
  { 'foreign.one_id' => 'self.one_id' },
);

__PACKAGE__->add_unique_constraint(['value']);

__PACKAGE__->validates(value => (presence=>1, length=>[2,48]));

__PACKAGE__->accept_nested_for('oneone');

1;
