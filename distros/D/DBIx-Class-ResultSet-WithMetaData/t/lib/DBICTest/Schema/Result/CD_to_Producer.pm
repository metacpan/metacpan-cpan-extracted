package # hide from PAUSE 
    DBICTest::Schema::Result::CD_to_Producer;

use base 'DBIx::Class::Core';

__PACKAGE__->table('cd_to_producer');
__PACKAGE__->add_columns(
  cd => { data_type => 'integer' },
  producer => { data_type => 'integer' },
);
__PACKAGE__->set_primary_key(qw/cd producer/);

__PACKAGE__->belongs_to(
  'cd', 'DBICTest::Schema::Result::CD',
  { 'foreign.cdid' => 'self.cd' }
);

__PACKAGE__->belongs_to(
  'producer', 'DBICTest::Schema::Result::Producer',
  { 'foreign.producerid' => 'self.producer' }
);

1;
