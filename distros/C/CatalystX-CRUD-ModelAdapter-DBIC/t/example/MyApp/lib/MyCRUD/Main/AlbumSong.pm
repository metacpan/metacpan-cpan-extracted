package MyCRUD::Main::AlbumSong;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('album_songs');
__PACKAGE__->add_columns(qw/ id album_id song_id /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( 'album_id' => 'MyCRUD::Main::Album' );
__PACKAGE__->belongs_to( 'song_id'  => 'MyCRUD::Main::Song' );
1;
