use strict;
use warnings;

use Test2::V0;

use lib qw(lib t);

use DBD::Mock::Session::GenerateFixtures;

use feature 'say';

note 'use mock data for fetchrow_hashref';

my $dbh = DBD::Mock::Session::GenerateFixtures->new( { file => 't/db_fixtures/01_fetchrow_hashref.t.json' } )->get_dbh();

my $sql = <<"SQL";
SELECT * FROM media_types WHERE id IN(?,?) ORDER BY id DESC
SQL
chomp $sql;

my $expected = [
    {
        'id'         => 2,
        'media_type' => 'audio'
    },
    {
        'media_type' => 'video',
        'id'         => 1
    }
];

subtest 'preapare and execute' => sub {
    my $sth = $dbh->prepare($sql);
    $sth->execute( 2, 1 );
    my $got = [];

    while ( my $row = $sth->fetchrow_hashref() ) {
        push @{$got}, $row;
    }

    is( $got, $expected, 'prepare and execute is ok' );
};

subtest 'preapare and execute with data from test' => sub {
    my $fixtures = [
        {
            "results"      => [ [ 2, "audio" ], [ 1, "video" ] ],
            "col_names"    => [ "id",           "media_type" ],
            "bound_params" => [ 2,              1 ],
            "statement"    => "SELECT * FROM media_types WHERE id IN(?,?)"
        },
    ];

    my $dbh2 = DBD::Mock::Session::GenerateFixtures->new( { data => $fixtures } )->get_dbh();
    my $sth  = $dbh2->prepare('SELECT * FROM media_types WHERE id IN(?,?)');
    $sth->execute( 2, 1 );
    my $got = [];

    while ( my $row = $sth->fetchrow_hashref() ) {
        push @{$got}, $row;
    }

    is( $got, $expected, 'prepare and execute is ok' );
};

subtest 'Use named binds to bind parameters' => sub {

    my $sth = $dbh->prepare('SELECT * FROM media_types WHERE id IN(:id, :id_2) ORDER BY id DESC');

    my $hash = {
        ':id'   => 2,
        ':id_2' => 1
    };

    while ( my ( $key, $val ) = each %{$hash} ) {
        $sth->bind_param( $key => $val );
    }
    $sth->execute();
    my $got = [];
    while ( my $row = $sth->fetchrow_hashref() ) {
        push @{$got}, $row;
    }

    is( $got, $expected, 'binding names params is ok' );
};

subtest 'no bind params' => sub {

    my $sth = $dbh->prepare('SELECT * FROM media_types order by id');
    $sth->execute();
    my $got      = [];
    my $expected = [
        {
            'media_type' => 'video',
            'id'         => 1
        },
        {
            'id'         => 2,
            'media_type' => 'audio'
        },
        {
            'media_type' => 'image',
            'id'         => 3
        }
    ];

    while ( my $row = $sth->fetchrow_hashref() ) {
        push @{$got}, $row;
    }

    is( $got, $expected, 'No bidding for parmas is okay' );

};

subtest 'no rows returned' => sub {

    my $sth = $dbh->prepare('SELECT * FROM media_types WHERE id IN(?,?)');

    $sth->execute( 11, 12 );

    my $got      = [];
    my $expected = [];

    while ( my $row = $sth->fetchrow_hashref() ) {
        push @{$got}, $row;
    }
    is( $got, $expected, 'no rows returned is ok' );

};

$dbh->disconnect();
done_testing();
