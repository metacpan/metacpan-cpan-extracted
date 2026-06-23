package # hide from PAUSE
    MigrationsTest::Schema::CD_to_Producer;

use warnings;
use strict;

use base qw/MigrationsTest::BaseResult/;

__PACKAGE__->table('cd_to_producer');
__PACKAGE__->add_columns(
  cd => { data_type => 'integer' },
  producer => { data_type => 'integer' },
  attribute => { data_type => 'integer', is_nullable => 1 },
);
__PACKAGE__->set_primary_key(qw/cd producer/);

# the undef condition in this rel is *deliberate*
# tests oddball legacy syntax
__PACKAGE__->belongs_to(
  'cd', 'MigrationsTest::Schema::CD'
);

__PACKAGE__->belongs_to(
  'producer', 'MigrationsTest::Schema::Producer',
  { 'foreign.producerid' => 'self.producer' },
  { on_delete => undef, on_update => undef },
);

1;
