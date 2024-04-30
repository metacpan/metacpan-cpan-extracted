use strict;
use warnings;

use Test2::V0;

use lib qw(lib t);

use MyDatabase qw(db_handle build_tests_db populate_test_db);
use DBD::Mock::Session::GenerateFixtures;

use feature 'say';

use Data::Walk;

my $dbh = db_handle('test.db');

build_tests_db($dbh);
populate_test_db($dbh);

$dbh = DBD::Mock::Session::GenerateFixtures->new({dbh => $dbh})->get_dbh();

my $sql = <<"SQL";
SELECT * FROM media_types WHERE id IN(?,?,?) ORDER BY id DESC
SQL

chomp $sql;

subtest 'selectall hashref with mutiple keys' => sub {

    my $expected = {
          '2' => {
                   'audio' => {
                                'media_type' => 'audio',
                                'id' => 2
                              }
                 },
          '1' => {
                   'video' => {
                                'media_type' => 'video',
                                'id' => 1
                              }
                 },
          '3' => {
                   'image' => {
                                'id' => 3,
                                'media_type' => 'image'
                              }
                 }
        };

    my $got = $dbh->selectall_hashref($sql, ['id', 'media_type'], undef, 2, 1, 3);
    is($got, $expected);
};

subtest 'selectall hashref with single key' => sub {

    my $expected = {
          '2' => {
                                'media_type' => 'audio',
                               'id' => 2
                 },
          '1' => {

                               'media_type' => 'video',
                                'id' => 1
                 },
          '3' => {
                                'id' => 3,
                                'media_type' => 'image'
                 }
        };

    my $got = $dbh->selectall_hashref($sql, 'id', undef, 2, 1, 3);
    is($got, $expected);
};


subtest 'selectall hashref with single key no data' => sub {

    my $expected = {};

    my $got = $dbh->selectall_hashref($sql, 'id', undef, 12, 12, 13);
    is($got, $expected);
};


done_testing();