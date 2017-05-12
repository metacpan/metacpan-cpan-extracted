#!/usr/bin/perl -w

use strict;

BEGIN	{ $| = 1; print "1..5\n"; }
END	{ print "not ok 1\n" unless $::XBaseloaded; }

$^W = 1;

print "Load the module: use XBase\n";
use XBase;
use IO::File;
$::XBaseloaded = 1;
print "ok 1\n";

my $dir = ( -d "t" ? "t" : "." );

$XBase::Base::DEBUG = 1;	# We want to see any problems

print "Set XBase::Base::SEEK_VIA_READ(1)\n";
XBase::Base::SEEK_VIA_READ(1);

print "Load table test.dbf\n";
my $table = new XBase("$dir/test", 'ignorememo' => 1);
print XBase->errstr(), 'not ' unless defined $table;
print "ok 2\n";

exit unless defined $table;	# It doesn't make sense to continue here ;-)


print "Load the records, one by one\n";
my $records_expected = join "\n",
	'0:1:Record no 1:::19960813',
	'1:2:No 2::1:19960814',
	'0:3:Message no 3::0:19960102';
my $records = join "\n", map {
	join ":", map { defined $_ ? $_ : "" } $table->get_record($_) }
								( 0 .. 2 );
if ($records_expected ne $records)
	{ print "Expected:\n$records_expected\nGot:\n$records\nnot "; }
print "ok 3\n";

print "And now will read a dbf from filehandle.\n";
XBase::Base::SEEK_VIA_READ(0);
my $fh = new IO::File "$dir/test.dbf";
my $fhtable = new XBase("-", 'fh' => $fh, 'ignorememo' => 1);
print XBase->errstr(), 'not ' unless defined $fhtable;
print "ok 4\n";

my $fhrecords = join "\n", map {
	join ":", map { defined $_ ? $_ : "" } $table->get_record($_) }
								( 0 .. 2 );
if ($records_expected ne $fhrecords)
	{ print "Expected:\n$records_expected\nGot:\n$fhrecords\nnot "; }
print "ok 5\n";

1;

