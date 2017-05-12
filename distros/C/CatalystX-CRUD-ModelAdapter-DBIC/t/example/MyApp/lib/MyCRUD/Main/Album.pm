package MyCRUD::Main::Album;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('albums');
__PACKAGE__->add_columns(qw/ id artist title /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(
    'album_songs' => 'MyCRUD::Main::AlbumSong',
    'album_id'
);
__PACKAGE__->many_to_many(
    'songs' => 'album_songs',
    'song_id'
);

1;
