package MyDB::Main::CdTrackJoin;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/ RDBOHelpers Core /);
__PACKAGE__->table('cd_track_join');
__PACKAGE__->add_columns(qw/ trackid cdid id /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( 'cd'    => 'MyDB::Main::Cd',    'cdid' );
__PACKAGE__->belongs_to( 'track' => 'MyDB::Main::Track', 'trackid' );

1;
