use strict;
use Test::More tests => 27;
use lib 't/lib';
use Data::Dump qw( dump );
use DBICx::TestDatabase;

use_ok('MyDBIC::Schema');

ok( my $cd = MyDBIC::Schema->class('Cd'), "Cd class" );
ok( my $m2m_tracks = $cd->relationship_info('cd_tracks'),
    "get m2m info for cd_tracks" );
ok( exists $m2m_tracks->{m2m}, "cd_tracks is a m2m" );
is_deeply(
    $m2m_tracks,
    {   attrs => {
            accessor       => "multi",
            cascade_copy   => 1,
            cascade_delete => 1,
            is_depends_on  => 0,
            join_type      => "LEFT",
        },
        class => "MyDBIC::Schema::CdTrackJoin",
        cond  => { "foreign.cdid" => "self.cdid" },
        m2m   => {
            class           => "MyDBIC::Schema::Cd",
            class_column    => 'cdid',
            foreign_class   => "MyDBIC::Schema::Track",
            foreign_column  => 'trackid',
            map_class       => "MyDBIC::Schema::CdTrackJoin",
            map_from        => "cd",
            map_from_column => "cdid",
            map_to          => "track",
            map_to_column   => "trackid",
            method_name     => "tracks",
            rel_name        => "cd_tracks",
        },
        source => "MyDBIC::Schema::CdTrackJoin",
    },
    "cd_tracks deep hash structure"
);

ok( my $track   = MyDBIC::Schema->class('Track'),         "Track class" );
ok( my $m2m_cds = $track->relationship_info('track_cds'), "track_cds" );
ok( exists $m2m_cds->{m2m}, "track_cds is a m2m" );
is_deeply(
    $m2m_cds,
    {   attrs => {
            accessor       => "multi",
            cascade_copy   => 1,
            cascade_delete => 1,
            is_depends_on  => 0,
            join_type      => "LEFT",
        },
        class => "MyDBIC::Schema::CdTrackJoin",
        cond  => { "foreign.trackid" => "self.trackid" },
        m2m   => {
            class           => "MyDBIC::Schema::Track",
            class_column    => 'trackid',
            foreign_class   => "MyDBIC::Schema::Cd",
            foreign_column  => 'cdid',
            map_class       => "MyDBIC::Schema::CdTrackJoin",
            map_from        => "track",
            map_from_column => "trackid",
            map_to          => "cd",
            map_to_column   => "cdid",
            method_name     => "cds",
            rel_name        => "track_cds",
        },
        source => "MyDBIC::Schema::CdTrackJoin",
    },
    "track_cds deep hash structure"
);

# test some data

ok( my $schema = DBICx::TestDatabase->new('MyDBIC::Schema'),
    "create temp db" );

ok( $schema->resultset('Artist')
        ->create( { artistid => 1, name => "bruce cockburn" } ),
    "create artist 1"
);

ok( $schema->resultset('Cd')
        ->create( { cdid => 1, artist => 1, title => 'best of' } ),
    "create cd 1"
);

ok( $schema->resultset('Cd')
        ->create( { cdid => 2, artist => 1, title => 'sunwheel dance' } ),
    "create cd 2"
);

ok( $schema->resultset('Track')->create(
        {   trackid => 1,
            title   => 'dialogue with the devil'
        }
    ),
    "create track 1"
);

ok( $schema->resultset('Track')->create(
        {   trackid => 2,
            title   => 'goin down slow'
        }
    ),
    "create track 2"
);

ok( $schema->resultset('CdTrackJoin')->create( { cdid => 1, trackid => 2 } ),
    "going down slow on best of"
);
ok( $schema->resultset('CdTrackJoin')->create( { cdid => 2, trackid => 2 } ),
    "going down slow on sunwheel dance"
);
ok( $schema->resultset('CdTrackJoin')->create( { cdid => 2, trackid => 1 } ),
    "dialogue on sunwheel dance"
);

ok( my $cd1 = $schema->resultset('Cd')->find( { cdid => 1 } ), "fetch cd 1" );
is( $cd1->has_related('tracks'), 1, $cd1->title . " has 1 tracks" );
ok( my $cd2 = $schema->resultset('Cd')->find( { cdid => 2 } ), "fetch cd 2" );
is( $cd2->has_related('tracks'), 2, $cd2->title . " has 2 tracks" );

# column_is_boolean
ok( $cd1->column_is_boolean('test_boolean'), "column_is_boolean" );
ok( !$cd1->column_is_boolean('artist'),      "column_is_boolean" );

# m2m to itself must be tested in a resultsource object not class
is_deeply(
    $cd1->relationship_info('relationships'),
    {   attrs => {
            accessor       => "multi",
            cascade_copy   => 1,
            cascade_delete => 1,
            is_depends_on  => 0,
            join_type      => "LEFT",
        },
        class => "MyDBIC::Schema::CdToItself",
        cond  => { "foreign.cdid_one" => "self.cdid" },
        m2m   => {
            class           => "MyDBIC::Schema::Cd",
            class_column    => "cdid",
            foreign_class   => "MyDBIC::Schema::Cd",
            foreign_column  => "cdid",
            map_class       => "MyDBIC::Schema::CdToItself",
            map_from        => "cd",
            map_from_column => "cdid_one",
            map_to          => "related",
            map_to_column   => "cdid_two",
            method_name     => "related_cds",
            rel_name        => "relationships",
        },
        source => "MyDBIC::Schema::CdToItself",
    },
    "m2m to itself"
);

# unique_value
is( $cd1->unique_value, '1', "unique_value" );
#diag( dump $cd1->artist );
is( $cd1->artist->unique_value, 'bruce cockburn', "artist unique value" );
