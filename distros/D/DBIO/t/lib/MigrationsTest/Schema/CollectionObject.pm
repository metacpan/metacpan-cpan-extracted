package # hide from PAUSE
    MigrationsTest::Schema::CollectionObject;

use warnings;
use strict;

use base qw/MigrationsTest::BaseResult/;

__PACKAGE__->table('collection_object');
__PACKAGE__->add_columns(
  'collection' => {
    data_type => 'integer',
  },
  'object' => {
    data_type => 'integer',
  },
);
__PACKAGE__->set_primary_key(qw/collection object/);

__PACKAGE__->belongs_to( collection => "MigrationsTest::Schema::Collection",
                         { "foreign.collectionid" => "self.collection" }
                       );
__PACKAGE__->belongs_to( object => "MigrationsTest::Schema::TypedObject",
                         { "foreign.objectid" => "self.object" }
                       );

1;
