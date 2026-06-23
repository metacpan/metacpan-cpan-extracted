package # hide from PAUSE
    MigrationsTest::Schema::Image;

use warnings;
use strict;

use base qw/MigrationsTest::BaseResult/;

__PACKAGE__->table('images');
__PACKAGE__->add_columns(
  'id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'artwork_id' => {
    data_type => 'integer',
    is_foreign_key => 1,
  },
  'name' => {
    data_type => 'varchar',
    size => 100,
  },
  'data' => {
    data_type => 'blob',
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('artwork', 'MigrationsTest::Schema::Artwork', 'artwork_id');

1;
