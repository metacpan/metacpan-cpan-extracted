package MyCRUD::Main::Song;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('songs');
__PACKAGE__->add_columns(qw/ id artist title length /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(
    'album_songs' => 'MyCRUD::Main::AlbumSong',
    'song_id'
);
__PACKAGE__->many_to_many(
    'albums' => 'album_songs',
    'album_id'
);

1;
