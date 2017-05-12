#!/usr/bin/perl -w

use strict;

BEGIN	{ $| = 1; print "1..10\n"; }
END	{ print "not ok 1\n" unless $::XBaseloaded; }


BEGIN { print "Load the module: use XBase\n"; }

use XBase;
$::XBaseloaded = 1;
print "ok 1\n";
print "This is XBase version $XBase::VERSION\n";

my $dir = ( -d "t" ? "t" : "." );
$XBase::Base::DEBUG = 1;        # We want to see any problems


print "Create the new XBase object, load the data from table test.dbf\n";
my $table = new XBase("$dir/test.dbf");
print XBase->errstr(), 'not ' unless defined $table;
print "ok 2\n";

exit unless defined $table;     # It doesn't make sense to continue here ;-)


print "Now, look into the object and check, if it has been filled OK\n";
my $info = sprintf "Version: 0x%02x, last record: %d, last field: %d",
	$table->version, $table->last_record, $table->last_field;
my $info_expect = 'Version: 0x83, last record: 2, last field: 4';
if ($info ne $info_expect)
	{ print "Expected:\n$info_expect\nGot:\n$info\nnot "; }
print "ok 3\n";


print "Check the field names\n";
my $names = join ' ', $table->field_names();
my $names_expect = 'ID MSG NOTE BOOLEAN DATES';
if ($names ne $names_expect)
	{ print "Expected: $names_expect\nGot: $names\nnot "; }
print "ok 4\n";


print "Get verbose header info (using header_info)\n";
$info = $table->get_header_info();
$info_expect = join '', <DATA>;
if ($info ne $info_expect)
	{ print "Expected: $info_expect\nGot: $info\nnot "; }
print "ok 5\n";


$XBase::Base::DEBUG = 0;

print "Check if loading table that doesn't exist will produce error\n";
my $badtable = new XBase("nonexistent.dbf");
print 'not ' if defined $badtable;
print "ok 6\n";


print "Check the returned error message\n";
my $errstr = XBase->errstr();
my $errstr_expect = 'Error opening file nonexistent.dbf:';
if (index($errstr, $errstr_expect) != 0)
	{ print "Expected: $errstr_expect\nGot: $errstr\nnot "; }
print "ok 7\n";

$table->close();


print "Load table without specifying the .dbf suffix\n";
$table = new XBase("$dir/test");
print "not " unless defined $table;
print "ok 8\n";


print <<EOF;
If all tests in this file passed, the module works to such an extend
that new XBase loads the table and correctly parses the information in
the file header.
EOF

print "Now reload with recompute_lastrecno\n";
$table = new XBase("$dir/test.dbf", recompute_lastrecno => 1);
print XBase->errstr(), 'not ' unless defined $table;
print "ok 9\n";

my $last_record = $table->last_record;
if ($last_record != 2) {
	print "recompute_lastrecno computed $last_record records\nnot ";
}
print "ok 10\n";


__DATA__
Filename:	t/test.dbf
Version:	0x83 (ver. 3 with DBT file)
Num of records:	3
Header length:	193
Record length:	279
Last change:	1996/8/17
Num fields:	5
Field info:
Num	Name		Type	Len	Decimal
1.	ID              N       5       0
2.	MSG             C       254     0
3.	NOTE            M       10      0
4.	BOOLEAN         L       1       0
5.	DATES           D       8       0
