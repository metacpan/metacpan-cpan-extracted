#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;

BEGIN {
	eval 'require DBD::SQLite';
	if ($@) {
		plan skip_all => 'DBD::SQLite not installed';
	}
	else {
		plan tests => 8;
	}
}

use_ok('DBIx::Class::Numeric');

use_ok('TestSchema');

my $db_file = "$FindBin::Bin/data/tmp.dat";
unlink($db_file);

my $schema = TestSchema->connect("dbi:SQLite:dbname=$db_file");
$schema->deploy;

my $row = $schema->resultset('BoundedTable')->create(
	{
		lower => 1,
		upper => 20,
		both => 10,
		bound_col_1 => 3,
		bound_col_2 => 6,
	}
);

is($row->lower, 3, "Lower bounded col changed to lower bound");
is($row->upper, 6, "Upper bounded col changed to upper bound");
is($row->both, 6, "Double bounded col changed to upper bound");

$row->bound_col_1(10);
$row->lower(3);
is($row->lower, 10, "Lower bounded col changed after bound col has changed");

$row->bound_col_2(30);
$row->upper(40);
$row->both(4);
is($row->upper, 30, "Upper bounded col changed after bound col has changed");
is($row->both, 10, "Double bounded col restricted correctly");

