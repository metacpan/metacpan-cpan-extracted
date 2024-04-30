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

$dbh = DBD::Mock::Session::GenerateFixtures->new({dbh => $dbh})->get_dbh();

my $sql = <<"SQL";
SELECT * FROM media_types WHERE id IN(?,?) ORDER BY id DESC
SQL

chomp $sql;
my $expected = [
          {
            'media_type' => 'audio'
          },
          {
            'media_type' => 'video',
          }
        ];


subtest 'preapare and execute' => sub {
    my $got = $dbh->selectall_arrayref($sql, { Slice => {'media_type' => 1} }, 2, 1);
    is($got, $expected);
};

subtest 'no bind parmas' => sub {
    
    
    my $expected = [
          {
            'media_type' => 'video',
            'id' => 1
          },
          {
            'id' => 2,
            'media_type' => 'audio'
          },
          {
            'media_type' => 'image',
            'id' => 3
          }
        ];
 
    my $got = $dbh->selectall_arrayref('SELECT * FROM media_types', { Slice => {}});
    
    is($got, $expected, 'no biding parmas is ok');

};

subtest 'no rows returned' => sub {
    
    my $sth = $dbh->prepare('SELECT * FROM media_types WHERE id IN(?,?)');

    my $got = $dbh->selectall_arrayref('SELECT * FROM media_types WHERE id IN(?,?)',{ Slice => {}}, 11, 12);
    my $expected = [];
    
    is($got, $expected, 'no biding parmas is ok');

};


done_testing();