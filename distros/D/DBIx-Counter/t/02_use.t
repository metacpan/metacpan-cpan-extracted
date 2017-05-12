# 02_use.t

use strict;
use File::Spec;
use Test::More;

#####
# prereqs 

for ( "DBI", "DBD::SQLite" ) {
    eval "require $_";
    if ( $@ ) {
        plan(skip_all=>"$_ is NOT available");
        exit(0);
    }
}

#####
# table setup

my %dsn = (
    DataSource  => "dbi:SQLite:dbname=" . File::Spec->catfile('t', 'counter.sqlt'),
    TableName   => 'counters'
);

my $dbh = DBI->connect($dsn{DataSource}, '', '', {RaiseError=>0, PrintError=>0});
unless ( $dbh ) {
    plan(skip_all=>"Couldn't establish connection with the server");
    exit(0);
}

my ($count) = $dbh->selectrow_array("SELECT COUNT(*) FROM $dsn{TableName}");
unless ( defined $count ) {
    unless( $dbh->do(qq|
        CREATE TABLE $dsn{TableName} (
            counter_id CHAR(64) NOT NULL PRIMARY KEY,
            value INT NOT NULL
        )|) ) {
        plan(skip_all=>$dbh->errstr);
        exit(0);
    }
}

#####
# tests start here

plan tests => 11;

use DBIx::Counter;

my $c = DBIx::Counter->new('test', dsn => $dsn{DataSource}, login=>'aap' );

isa_ok( $c, 'DBIx::Counter');

is($c->value, 0, "c is a new counter at 0");

$c->inc;

is($c->value, 1, "inc works: c == 1");

$c--;

is($c->value, 0, "-- works");

$c++;

is($c->value, 1, "++ works");
is("$c", "1", "stringification works");

my $d;
eval {
$d = DBIx::Counter->new('test2');
};

like($@, qr/Unable to connect to database/, "croaks OK without proper arguments");

$d = DBIx::Counter->new('test', dbh => $dbh);
is($d->value, 1, "Using a predefined dbh works");
$d++;
is($c->value, 2, "multiple counters work");

local $DBIx::Counter::DSN   = $dsn{DataSource};
local $DBIx::Counter::LOGIN = '';

$d = DBIx::Counter->new('test2', 4);

isa_ok( $d, 'DBIx::Counter', "package variable settings work: d");
is($d->value, 4, "d == 4: initial works");

$c->_db->do(qq{delete from $dsn{TableName}});

# to avoid warnings
local $DBIx::Counter::DSN   = $dsn{DataSource};
local $DBIx::Counter::LOGIN = '';

