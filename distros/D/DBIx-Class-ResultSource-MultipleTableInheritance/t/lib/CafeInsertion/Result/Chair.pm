package # hide from PAUSE
	CafeInsertion::Result::Chair;

use base qw(DBIx::Class::Core);

__PACKAGE__->table('chair');

__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_auto_increment => 1 },
  name => { data_type => 'varchar', size => 255 }
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
  'coffees',
  'CafeInsertion::Result::Coffee',
  { 'foreign.id' => 'self.id' }
);


1;
