#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;

use DBI;

use DBIx::Admin::CreateTable;

use DBIx::Tree::Persist;

use File::Temp;

use File::Slurp; # For read_file.

use FindBin;

# -----------------------------------------------

sub insert_hash
{
	my($dbh, $table_name, $field_values) = @_;

	my(@fields) = sort keys %$field_values;
	my(@values) = @{$field_values}{@fields};
	my($sql)    = sprintf 'insert into %s (%s) values (%s)', $table_name, join(',', @fields), join(',', ('?') x @fields);

	$dbh -> do($sql, {}, @values);

	return 0;

} # End of insert_hash.

# -----------------------------------------------

sub populate_table
{
	my($dbh, $table_name) = @_;
	my($data) = read_a_file("$table_name.txt");

	my(@field);
	my($id);
	my($parent_id);
	my($result);

	for (@$data)
	{
		@field     = split(/\s+/, $_);
		$parent_id = pop @field;
		$id        = pop @field;
		$result    = insert_hash
		(
			$dbh,
			$table_name,
		 	{
			 class     => 'Tree',
			 id        => $id,
			 parent_id => $parent_id eq 'NULL' ? 0 : $parent_id,
			 value     => join(' ', @field),
		 	}
		);
	}

	return 0;

}	# End of populate_table.

# -----------------------------------------------

sub read_a_file
{
	my($input_file_name) = @_;
	$input_file_name = "$FindBin::Bin/../data/$input_file_name";
	my(@line)        = read_file($input_file_name);

	chomp @line;

	return [grep{! /^$/ && ! /^#/} map{s/^\s+//; s/\s+$//; $_} @line];

} # End of read_a_file.

# ------------------------------------------------

my($table_name)                        = 'two';
my($temp_file_handle, $temp_file_name) = File::Temp::tempfile('temp.XXXX', EXLOCK => 0, UNLINK => 1);
my(@dsn)                               =
(
$ENV{DBI_DSN}  || "dbi:SQLite:$temp_file_name",
$ENV{DBI_USER} || '',
$ENV{DBI_PASS} || '',
);
my($dbh) = DBI -> connect(@dsn, {RaiseError => 1, PrintError => 1, AutoCommit => 1});

ok($dbh, 'Created $dbh');

my($creator) = DBIx::Admin::CreateTable -> new(dbh => $dbh, verbose => 0);

ok($creator, 'Created $creator');

$creator -> drop_table($table_name);

ok(1, "Dropped table '$table_name' if it existed");

my($primary_key) = $creator -> generate_primary_key_sql($table_name);

ok($primary_key, "Generated primary key syntax for $ENV{DBI_DSN}");

my($result) = $creator -> create_table(<<SQL);
create table $table_name
(
id integer not null primary key,
parent_id integer not null,
class varchar(255) not null,
value varchar(255)
)
SQL

ok(! defined $DBI::errstr, "created table $table_name");

$result = populate_table($dbh, $table_name);

ok(! defined $DBI::errstr, "populated table $table_name");
ok($result == 0, 'populate_table() worked');

my($persist) = DBIx::Tree::Persist -> new(dbh => $dbh, table_name => $table_name, verbose => 1);

ok($persist, 'DBIx::Tree::Persist.new() worked');

$result = $persist -> run;
ok($result == 0, 'DBIx::Tree::Persist.run() worked');

$dbh -> do("drop table $table_name");

ok(! defined $DBI::errstr, "dropped table $table_name");

$dbh -> disconnect;
