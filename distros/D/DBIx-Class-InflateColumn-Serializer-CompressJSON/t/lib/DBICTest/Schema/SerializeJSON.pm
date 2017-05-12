#
# This file is part of DBIx-Class-InflateColumn-Serializer-CompressJSON
#
# This software is copyright (c) 2012 by Weborama.  No
# license is granted to other entities.
#
package # hide from PAUSE
    DBICTest::Schema::SerializeJSON;

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
    serializer_class => 'JSON'
  },
  'serial2' => {
    data_type => 'varchar',
    serializer_class => 'JSON'
  }
);

__PACKAGE__->set_primary_key('testtable_id');

1;

