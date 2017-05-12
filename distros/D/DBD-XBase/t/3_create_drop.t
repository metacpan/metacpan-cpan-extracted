#!/usr/bin/perl -w

use strict;

BEGIN	{ $| = 1; print "1..11\n"; }
END	{ print "not ok 1\n" unless $::XBaseloaded; }


print "Load the module: use XBase\n";

use XBase;
$::XBaseloaded = 1;
print "ok 1\n";

my $dir = ( -d "t" ? "t" : "." );

$XBase::Base::DEBUG = 1;        # We want to see any problems
$XBase::CLEARNULLS = 1;         # Yes, we want that


print "Unlinking newtable.dbf and newtable.dbt\n";

if (-f "$dir/newtable.dbf")
	{ unlink "$dir/newtable.dbf"
		or print "Error unlinking $dir/newtable.dbf: $!\n"; }
if (-f "$dir/newtable.dbt")
	{ unlink "$dir/newtable.dbt"
		or print "Error unlinking $dir/newtable.dbt: $!\n"; }


print "Create new table, newtable.dbf & newtable.dbt, with types C M D F L\n";

my $table = create XBase('name' => "$dir/newtable",
	'field_names' => [ 'NAME', 'COMMENT', 'UID', 'FLOAT', 'ACTIVE' ],
	'field_types' => [ 'C', 'M', 'D', 'F', 'L' ],
	'field_lengths' => [ 15, 10, 8, 6, 1 ],
	'field_decimals' => [ undef, undef, undef, 2, undef ],
	codepage => 1);

print "not " unless defined $table;
print "ok 2\n";

exit unless defined $table;


print "Check if both (dbf and dbt) files were created\n";

print "not " unless -f "$dir/newtable.dbf";
print "ok 3\n";
print "not " unless -f "$dir/newtable.dbt";
print "ok 4\n";


print "Check their lengths (expect 194 and 512)\n";
my $len = -s "$dir/newtable.dbf";
if ($len != 194)
	{ print "Got $len\nnot "; }
print "ok 5\n";
$len = -s "$dir/newtable.dbt";
if ($len != 512)
	{ print "Got $len\nnot "; }
print "ok 6\n";


print "Now, fill two records\n";

$table->set_record(0, 'Michal', 'Michal seems to be a nice guy',
		24513, 186.45, 1) or print $table->errstr(), 'not ';
print "ok 7\n";
$table->set_record(1, 'Martin', 'Martin is fine, too', 89, 13, 0)
		or print $table->errstr(), 'not ';
print "ok 8\n";

print "Check the header of the newly created table\n";

my $header = $table->get_header_info();
$header =~ s!^Last change:\t.*$!Last change:\txxxx/xx/xx!m;
$header =~ s!^Filename:\tt/!Filename:\t!;

my $goodheader = join '', <DATA>;
if ($header ne $goodheader)
	{
	print "Got header:\n", $header;
	print "Good header is:\n", $goodheader;
	print "not ";
	}
print "ok 9\n";


print "Drop the table\n";
$table->drop() or print "not ";
print "ok 10\n";

print "Check if the files newtable.dbf and newtable.dbt have been deleted\n";
print "not " if (-f "$dir/newtable.dbf" or -f "$dir/newtable.dbt");
print "ok 11\n";





### use XBase;
### my $table = XBase->create(
### 	'name' => 'tab.dbf',
### 	'memofile' => 'tab.fpt',
### 	'field_names' => [ 'ID', 'MSG' ],
### 	'field_types' => [ 'C', 'M' ],
### 	'field_lengths' => [ 20 ],
### 	'field_decimals' => []
### ) or die XBase->errstr;
### $table->set_record(0, 'jezek', 'krtek');

__DATA__
Filename:	newtable.dbf
Version:	0x83 (ver. 3 with DBT file)
Num of records:	2
Header length:	193
Record length:	41
Last change:	xxxx/xx/xx
Num fields:	5
Field info:
Num	Name		Type	Len	Decimal
1.	NAME            C       15      0
2.	COMMENT         M       10      0
3.	UID             D       8       0
4.	FLOAT           F       6       2
5.	ACTIVE          L       1       0
