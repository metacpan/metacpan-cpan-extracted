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
		plan tests => 7;
	}
}

use_ok('DBIx::Class::Numeric');

use_ok('TestSchema');

my $db_file = "$FindBin::Bin/data/tmp.dat";
unlink($db_file);

my $schema = TestSchema->connect("dbi:SQLite:dbname=$db_file");
$schema->deploy;

my $row = $schema->resultset('TestTable')->create(
	{
		baz       => 3,
		simple    => 20,
		with_args => 150,
	}
);

is( $row->baz,       5,  "Col set to min when create set to a lower val" );
is( $row->simple,    20, "Col not changed during create" );
is( $row->with_args, 99, "Col set to max when create set to a higher val" );

$row->baz(11);
is( $row->baz,       10,  "Col set to max when setting to a higher val" );

$row->update({ with_args => 120 });
is($row->with_args, 99, "Calling update() applies restrictions");

