package # hide from PAUSE
    DBICTest::Schema::Blog;
use strict;
use warnings;
use base qw( DBIx::Class );
__PACKAGE__->load_components(qw( FromValidators Core ));

__PACKAGE__->table('blog');

__PACKAGE__->add_columns(
  'id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'name' => {
    data_type => 'varchar',
    size      => 100,
    is_nullable => 1,
  },
  'url' => {
    data_type => 'varchar',
    size      => 100,
    is_nullable => 1,
  },
);

__PACKAGE__->set_primary_key('id');

1;
