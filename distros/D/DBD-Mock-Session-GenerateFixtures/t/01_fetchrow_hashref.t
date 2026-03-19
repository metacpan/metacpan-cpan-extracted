use strict;
use warnings;

use Test2::V0;

use lib qw(lib t);

use MyDatabase qw(db_handle build_tests_db populate_test_db);
use DBD::Mock::Session::GenerateFixtures;

use feature 'say';

my $dbh = db_handle('test.db');

build_tests_db($dbh);
populate_test_db($dbh);

$dbh = DBD::Mock::Session::GenerateFixtures->new( { dbh => $dbh } )->get_dbh();

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

note 'generate mock data for fetchrow_hashref';

subtest 'preapare and execute' => sub {
    my $sth = $dbh->prepare($sql);
    $sth->execute( 2, 1 );
    my $got = [];

    while ( my $row = $sth->fetchrow_hashref() ) {
        push @{$got}, $row;
    }

    is( $got, $expected, 'prepare and execute is ok' );
};

subtest 'Use named binds to bind parameters' => sub {

    my $sth = $dbh->prepare('SELECT * FROM media_types WHERE id IN(:id, :id_2) ORDER BY id DESC');
    $sth->bind_param(
        ':id' => 2,
        undef
    );
    $sth->bind_param(
        ':id_2' => 1,
        undef
    );
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
