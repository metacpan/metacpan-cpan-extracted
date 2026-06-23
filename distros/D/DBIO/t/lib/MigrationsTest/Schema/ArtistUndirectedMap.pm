package # hide from PAUSE
    MigrationsTest::Schema::ArtistUndirectedMap;

use warnings;
use strict;

use base qw/MigrationsTest::BaseResult/;

__PACKAGE__->table('artist_undirected_map');
__PACKAGE__->add_columns(
  'id1' => { data_type => 'integer' },
  'id2' => { data_type => 'integer' },
);
__PACKAGE__->set_primary_key(qw/id1 id2/);

__PACKAGE__->belongs_to( 'artist1', 'MigrationsTest::Schema::Artist', 'id1', { on_delete => 'RESTRICT', on_update => 'CASCADE'} );
__PACKAGE__->belongs_to( 'artist2', 'MigrationsTest::Schema::Artist', 'id2', { on_delete => undef, on_update => undef} );
__PACKAGE__->has_many(
  'mapped_artists', 'MigrationsTest::Schema::Artist',
  [ {'foreign.artistid' => 'self.id1'}, {'foreign.artistid' => 'self.id2'} ],
  { cascade_delete => 0 },
);

1;
