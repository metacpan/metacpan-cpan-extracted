package MyDB::Main::Track;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/RDBOHelpers Core/);
__PACKAGE__->table('track');
__PACKAGE__->add_columns(qw/ trackid title /);
__PACKAGE__->set_primary_key('trackid');
__PACKAGE__->has_many(
    'track_cds' => 'MyDB::Main::CdTrackJoin',
    'trackid'
);
__PACKAGE__->many_to_many(
    'cds' => 'track_cds',
    'cd'
);

1;
