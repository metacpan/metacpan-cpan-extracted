package TestApp::Schema::Result::Resource::Album;
use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('album');
__PACKAGE__->add_columns(
    id => {
        data_type => 'int',
        is_numeric => 1,
        is_auto_increment => 1
    },
    artist_id => {
        data_type => 'int',
        is_numeric => 1,
    },
    name => {
        data_type => 'varchar',
    },
);

__PACKAGE__->set_primary_key ('id');

__PACKAGE__->belongs_to(
    'artist',
    'TestApp::Schema::Result::Resource::Artist',
    'artist_id'
);

__PACKAGE__->has_many(
   'songs',
   'TestApp::Schema::Result::Resource::Song',
   'album_id'
);

__PACKAGE__->has_many(
   'artworks',
   'TestApp::Schema::Result::Resource::Artwork',
   'album_id'
);

__PACKAGE__->has_many(
   'lyrics',
   'TestApp::Schema::Result::Resource::Lyric',
   'album_id'
);

1;
