use strict;
use warnings;

use Test2::V0;

use lib qw(lib t);

use DBD::Mock::Session::GenerateFixtures;

use feature 'say';

use Data::Walk;

my $dbh = DBD::Mock::Session::GenerateFixtures->new({file => 't/db_fixtures/11_selectcol_arrayref.t.json'})->get_dbh();

my $sql = <<"SQL";
SELECT * FROM media_types WHERE id IN(?,?,?) ORDER BY id DESC
SQL
chomp $sql;

subtest 'selectcol_arrayreff mutiple columns' => sub {
    my $got = $dbh->selectcol_arrayref($sql, { Columns=>[1,2] }, 2, 1, 3);
    my $expected = [
          3,
          'image',
          2,
          'audio',
          1,
          'video'
        ];

    is($got, $expected);
};

subtest 'selectcol_arrayreff single column' => sub {
    my $got = $dbh->selectcol_arrayref($sql, { Columns=>[1] }, 2, 1, 3);
    my $expected = [
          3,
          2,
          1,
        ];

    is($got, $expected);
};

subtest 'selectcol_arrayreff single column' => sub {
    my $got = $dbh->selectcol_arrayref($sql, undef, 2, 1, 3);
    my $expected = [
          3,
          2,
          1,
        ];

    is($got, $expected);
};

done_testing();