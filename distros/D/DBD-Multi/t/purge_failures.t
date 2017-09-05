# vim: ft=perl
use Test::More 'no_plan';
use strict;
$^W = 1;

# Test that failing dbs are eventually re-tried.

use DBI;
use DBD::SQLite;
use DBD::Multi;

my %SOURCE = ( 1 => "dbi:SQLite:one.db",
               2 => "dbi:SQLite:two.db" );
my $WORKING = 0;

init();
my $c = db_connect();
my @count = (undef,0,0);

for (1..100) {
    my $val = $c->selectrow_array("SELECT id FROM multi");
    $count[$val]++;
}

is($count[1], 0, "first db returned no values because it had crashed." );
is($count[2], 100, "second db used for every query." );

@count = (undef,0,0);

$WORKING = 1;
sleep( 3 );

for (1..100) {
    my $val = $c->selectrow_array("SELECT id FROM multi");
    $count[$val]++;
}

is($count[1], 100, "first db used every time due to higher priority." );
is($count[2], 0, "second db unused because first db was available." );

unlink "$_.db" for qw[one two];

sub init {
    unlink "$_.db" for qw[one two];
    # Set up the first DB with a value of 1
     my $dbh_1 = DBI->connect($SOURCE{1});
     is $dbh_1->do("CREATE TABLE multi(id int)"), '0E0', 'do create successful';
     is($dbh_1->do("INSERT INTO multi VALUES(1)"), 1, 'insert via do works');

    # And the second DB with the value of 2
     $dbh_1 = DBI->connect($SOURCE{2});
     is $dbh_1->do("CREATE TABLE multi(id int)"), '0E0', 'do create successful';
     is($dbh_1->do("INSERT INTO multi VALUES(2)"), 1, 'insert via do works');
}

sub db_connect {
    my $first = sub { $WORKING ? DBI->connect($SOURCE{1}) : undef };
    my $second = sub { DBI->connect($SOURCE{2}) };
    return DBI->connect('DBI:Multi:', undef, undef, {
        dsns => [
            1 => $first,
            2 => $second,
        ],
        failed_expire => 2,
    });
}
