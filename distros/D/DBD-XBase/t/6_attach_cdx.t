#!/usr/bin/perl -w

use strict;

BEGIN	{ $| = 1; print "1..7\n"; }
END	{ print "not ok 1\n" unless $::XBaseloaded; }

$XBase::Index::VERBOSE = 0;

print "Load the module: use XBase\n";
use XBase;
$::XBaseloaded = 1;
print "ok 1\n";

my $dir = ( -d "t" ? "t" : "." );

$XBase::Base::DEBUG = 1;        # We want to see any problems


print "Unlink write.dbf and write.dbt, make a copy of test.dbf and test.dbt\n";

my @FILES = map { "$dir/$_" } qw! rooms1.dbf rooms1.cdx !;
for (@FILES) {
	if (-f $_ and not unlink $_)
		{ print "Error unlinking $_: $!\n"; }
	}

use File::Copy;
copy("$dir/rooms.dbf", "$dir/rooms1.dbf");
copy("$dir/rooms.cdx", "$dir/rooms1.cdx");


for (@FILES) {
	if (not -f $_) {
		die "The files to do the write tests were not created, aborting\n";
		}		# Does not make sense to continue
	}


print "ok 2\n";

print "Open table $dir/rooms1\n";
my $table = new XBase "$dir/rooms1" or do
        {
        print XBase->errstr, "not ok 3\n";
        exit
        };
print "ok 3\n";


print "Attach indexfile $dir/rooms1.cdx\n";
$table->attach_index("$dir/rooms1.cdx") or do {
        print XBase->errstr, "not ok 4\n";
        exit
        };
print "ok 4\n";


print "Delete record 26: Dub:Main\n";
$table->delete_record(26) or print STDERR $table->errstr, 'not ';
print "ok 5\n";


print "Undelete record 26: Dub:Main\n";
$table->undelete_record(26) or print STDERR $table->errstr, 'not ';
print "ok 6\n";


print "Append record: Krtek:Jezek\n";
$table->set_record($table->last_record + 1, 'Krtek', 'Jezek') or print STDERR $table->errstr, 'not ';
print "ok 7\n";


