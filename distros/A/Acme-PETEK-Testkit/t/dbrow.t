#!/usr/bin/perl -w

use strict;
use Test::More;
use Test::DatabaseRow;

use DBI;
eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite required" if $@;
plan tests => 5;

my $dbh = DBI->connect("dbi:SQLite:dbname=db.sqlite","","");
isa_ok($dbh,'DBI::db');
local $Test::DatabaseRow::dbh = $dbh;

ok($dbh->do('CREATE TABLE foo ( id int, value varchar(10) )'),'table created');
ok($dbh->do('INSERT INTO foo (id,value) VALUES (?,?)',undef,1,"bar"),'row inserted');

row_ok( table => 'foo',
	where => [ id => 1 ],
	tests => [ value => "bar" ],
	label => "row 1 has value 'bar'");

ok(unlink('db.sqlite'),'db.sqlite removed');
