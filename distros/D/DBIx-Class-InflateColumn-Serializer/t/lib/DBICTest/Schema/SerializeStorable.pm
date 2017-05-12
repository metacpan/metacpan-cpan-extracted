package # hide from PAUSE
    DBICTest::Schema::SerializeStorable;

use strict;
use warnings;

use base qw/DBIx::Class/;

__PACKAGE__->load_components (qw/InflateColumn::Serializer Core/);

__PACKAGE__->table('testtable');
__PACKAGE__->add_columns(
  'testtable_id' => {
    data_type => 'integer',
  },
  'serial1' => {
    data_type => 'varchar',
    size => 100,
    serializer_class => 'Storable',
    is_nullable => 1,
  },
  'serial2' => {
    data_type => 'varchar',
    serializer_class => 'Storable',
    is_nullable => 1,
  }
);

__PACKAGE__->set_primary_key('testtable_id');

1;

