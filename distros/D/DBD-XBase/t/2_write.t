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


print "Unlink write.dbf and write.dbt, make a copy of test.dbf and test.dbt\n";

my @FILES = map { "$dir/$_" } qw! write.dbf write.dbt write1.dbf write1.FPT !;
for (@FILES) {
	if (-f $_ and not unlink $_)
		{ print "Error unlinking $_: $!\n"; }
	}

use File::Copy;
copy("$dir/test.dbf", "$dir/write.dbf");
copy("$dir/test.dbt", "$dir/write.dbt");
copy("$dir/afox5.dbf", "$dir/write1.dbf");
copy("$dir/afox5.FPT", "$dir/write1.FPT");


for (@FILES) {
	if (not -f $_) {
		die "The files to do the write tests were not created, aborting\n";
		}		# Does not make sense to continue
	}


print "ok 2\n";


print "Load the table write.dbf\n";
my $table = new XBase("$dir/write.dbf");
print XBase->errstr, 'not ' unless defined $table;
print "ok 3\n";

exit unless defined $table;


print "Check the last record number (number of records, in fact)\n";
my $last_record = $table->last_record();
if ($last_record != 2)
	{ print "Expecting 2, got $last_record\nnot "; }
print "ok 4\n";


print "Overwrite the record and check it back\n";
$table->set_record(1, 5, 'New message', 'New note', 1, '19700101')
	or print STDERR $table->errstr();
$table->get_record(0);		# Force emptying caches
my $result = join ':', map { defined $_ ? $_ : '' } $table->get_record(1);
my $result_expected = '0:5:New message:New note:1:19700101';
if ($result_expected ne $result)
	{ print "Expected: $result_expected\nGot: $result\nnot "; }
print "ok 5\n";


print "Did last record number stay the same?\n";
$last_record = $table->last_record();
if ($last_record != 2)
	{ print "Expecting 2, got $last_record\nnot "; }
print "ok 6\n";


print "Now append data and read them back\n";
$table->set_record(3, 245, 'New record no 4', 'New note for record 4', undef, '19700102');
$table->get_record(0);			# Force flushing cache
$result = join ':', map { defined $_ ? $_ : '' } $table->get_record(3);
$result_expected = '0:245:New record no 4:New note for record 4::19700102';
if ($result_expected ne $result)
	{ print "Expected: $result_expected\nGot: $result\nnot "; }
print "ok 7\n";


print "Now the number of records should have increased\n";
$last_record = $table->last_record();
if ($last_record != 3)
	{ print "Expecting 3, got $last_record\nnot "; }
print "ok 8\n";


print "Load the table write1.dbf\n";
$table = new XBase("$dir/write1.dbf");
print XBase->errstr, 'not ' unless defined $table;
print "ok 9\n";

exit unless defined $table;

print "Append one record\n";
$table->set_record(2, 'd22', 15, 'Mike', 'third desc.', 'third mess.')
	or print STDERR $table->errstr();
$table->get_record(0);		# Force emptying caches
$result = join ':', map { defined $_ ? $_ : '' } $table->get_record(2);
$result_expected = '0:d22:15:Mike:third desc.:third mess.';
if ($result_expected ne $result)
	{ print "Expected: $result_expected\nGot: $result\nnot "; }
print "ok 10\n";


print "Check the size of the resulting fpt\n";
$table->close;
my $size = -s "$dir/write1.FPT";
if ($size != 896) {
	print "Expected size 896, got $size\nnot "
	}
print "ok 11\n";

1;
