use strict;
use warnings;

use Test2::V0;

use lib qw(lib t);

use DBD::Mock::Session::GenerateFixtures;

use feature 'say';

my $dbh = DBD::Mock::Session::GenerateFixtures->new({file => './t/db_fixtures/03_fetchrow_arrayref.t.json'})->get_dbh();

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
    
    while (my $row = $sth->fetchrow_arrayref()) {
        push @{$got}, [@{$row}];
    }
    
    is($got, $expected, 'prepare and execute is ok');
};

subtest 'Use positional binding to bind parameters' => sub {

    my $sth = $dbh->prepare($sql);
    $sth->bind_param(1, 1, undef);
    $sth->bind_param(2, 2, undef);
    $sth->execute();
    my $got = [];
    
    while (my $row = $sth->fetchrow_arrayref()) {
        push @{$got}, [@{$row}];
    }

    is($got, $expected, 'postional bind is ok');
};

subtest 'Use named binds to bind parameters' => sub {
    
    my $sth = $dbh->prepare('SELECT * FROM media_types WHERE id IN(:id, :id_2) ORDER BY id DESC');
    $sth->bind_param(':id' => 2, undef);
    $sth->bind_param(':id_2' => 1, undef);
    $sth->execute();
    my $got = []; 
    while (my $row = $sth->fetchrow_arrayref()) {
        push @{$got}, [@{$row}];
    }

    is($got, $expected, 'The named parameter binding is ok');
};

subtest 'no bind paramas' => sub {
    
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
 
    while (my $row = $sth->fetchrow_arrayref()) {
        push @{$got}, [@{$row}];
    }
    
    is($got, $expected, 'no biding paramas is ok');

};

subtest 'no rows returned' => sub {
    
    my $sth = $dbh->prepare('SELECT * FROM media_types WHERE id IN(?,?)');
 
    $sth->execute(11, 12);
   
    my $got = [];
    my $expected = [];
    
    while (my $row = $sth->fetchrow_arrayref()) {
        push @{$got}, [@{$row}];
    }
    is($got, $expected, 'no rows returned is ok');

};

$dbh->disconnect();
done_testing();