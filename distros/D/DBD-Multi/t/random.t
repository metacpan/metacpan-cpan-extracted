# vim: ft=perl
use Test::More 'no_plan';
use strict;
$^W = 1;

# Test that two dbs with the same priority are actually randomly selected.

use DBI;
use DBD::SQLite;
use DBD::Multi;

init();
my $c = db_connect();
my @count = (undef,0,0);

my ($one_cnt,$two_cnt) = (0,0);
for (1..100) {
    my $val = $c->selectrow_array("SELECT id FROM multi");
    $count[$val]++;
}

ok($count[1], "first db with same priority was selected through random process ($count[1]/100)");
ok($count[2], "second db with same priority was selected through random process ($count[2]/100)");

@count = (undef,0,0);

for (1..100) {
    my $c = db_connect();
    my $val = $c->selectrow_array("SELECT id FROM multi");
    $count[$val]++;
}

ok($count[1], "first db with same priority was selected through random process on initial connect ($count[1]/100)");
ok($count[2], "second db with  same priority was selected through random process on initial connect ($count[2]/100)");


unlink "$_.db" for qw[one two];

sub init {
    # Set up the first DB with a value of 1
     my $dbh_1 = DBI->connect("dbi:SQLite:one.db");
     is $dbh_1->do("CREATE TABLE multi(id int)"), '0E0', 'do create successful';
     is($dbh_1->do("INSERT INTO multi VALUES(1)"), 1, 'insert via do works');

    # And the second DB with the value of 2
     $dbh_1 = DBI->connect("dbi:SQLite:two.db");
     is $dbh_1->do("CREATE TABLE multi(id int)"), '0E0', 'do create successful';
     is($dbh_1->do("INSERT INTO multi VALUES(2)"), 1, 'insert via do works');
}

sub db_connect {
    return DBI->connect('DBI:Multi:', undef, undef, {
        dsns => [
            1 => ['dbi:SQLite:one.db', '',''],
            1 => ['dbi:SQLite:two.db','',''],
        ],
    });
}
