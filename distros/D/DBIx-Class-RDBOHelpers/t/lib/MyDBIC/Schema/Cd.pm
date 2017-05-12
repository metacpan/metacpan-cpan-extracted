package MyDBIC::Schema::Cd;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/ RDBOHelpers Core /);
__PACKAGE__->table('cd');
__PACKAGE__->add_columns(qw/ cdid artist title /);
__PACKAGE__->add_column(
    'test_boolean' => {
        data_type         => 'boolean',
        is_auto_increment => 0,
        is_nullable       => 1,
        default_value     => 1,
    }
);
__PACKAGE__->set_primary_key('cdid');
__PACKAGE__->belongs_to( 'artist' => 'MyDBIC::Schema::Artist' );
__PACKAGE__->has_many(
    'cd_tracks' => 'MyDBIC::Schema::CdTrackJoin',
    'cdid'
);
__PACKAGE__->many_to_many(
    'tracks' => 'cd_tracks',
    'track'
);

# relationships
__PACKAGE__->has_many(
    relationships => 'MyDBIC::Schema::CdToItself' => 'cdid_one' );
__PACKAGE__->many_to_many( related_cds => 'relationships' => 'related' );


1;
