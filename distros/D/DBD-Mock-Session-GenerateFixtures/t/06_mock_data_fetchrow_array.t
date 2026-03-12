use strict;
use warnings;

use Test2::V0;

use lib qw(lib t);

use DBD::Mock::Session::GenerateFixtures;

use feature 'say';

my $dbh = DBD::Mock::Session::GenerateFixtures->new({file => 't/db_fixtures/05_fetchrow_array.t.json'})->get_dbh();

my $sql = <<"SQL";
SELECT * FROM media_types WHERE id IN(?,?) ORDER BY id DESC
SQL

chomp $sql;
my $expected = [
        [ 2, 'audio' ],
        [ 1, 'video' ],
    ];

subtest 'preapare and execute' => sub {
    my $sth = $dbh->prepare($sql);
    $sth->execute(2, 1);
    my $got = [];
    
    while (my @row = $sth->fetchrow_array()) {
        push @{$got}, \@row;
    }
    
    is($got, $expected, 'prepare and execute is ok');
};

subtest 'bind params with named bind' => sub {
    
    my $sth = $dbh->prepare('SELECT * FROM media_types WHERE id IN(:id, :id_2) ORDER BY id DESC');

    my $hash = {
        ':id' => 2,
        ':id_2' => 1
    };

    while (my ($key, $val) = each %{$hash}) {
        $sth->bind_param($key => $val);
    }

    $sth->execute();
    my $got = []; 
    while (my @row = $sth->fetchrow_array()) {
        push @{$got}, \@row;
    }

    is($got, $expected, 'binding names params is ok');
};

subtest 'no bind parmas' => sub {
    
    my $sth = $dbh->prepare('SELECT * FROM media_types');
    $sth->execute();
    my $got = [];
    my $expected = [
          [
            1,
            'video',
          ],
          [
             2,
            'audio',

          ],
          [
            3,
            'image',

          ]
        ];
 
    while (my @row = $sth->fetchrow_array()) {
        push @{$got}, \@row;
    }
    
    is($got, $expected, 'no biding parmas is ok');

};

subtest 'no rows returned' => sub {
    
    my $sth = $dbh->prepare('SELECT * FROM media_types WHERE id IN(?,?)');
 
    $sth->execute(11, 12);
   
    my $got = [];
    my $expected = [];
    
    while (my @row = $sth->fetchrow_array) {
        push @{$got}, \@row;
    }
    is($got, $expected, 'no biding parmas is ok');

};

$dbh->disconnect();
done_testing();
