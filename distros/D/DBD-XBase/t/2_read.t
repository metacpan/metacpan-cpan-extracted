#!/usr/bin/perl -w

use strict;

BEGIN	{ $| = 1; print "1..9\n"; }
END	{ print "not ok 1\n" unless $::XBaseloaded; }


print "Load the module: use XBase\n";
use XBase;
$::XBaseloaded = 1;
print "ok 1\n";

my $dir = ( -d "t" ? "t" : "." );

$XBase::Base::DEBUG = 1;	# We want to see any problems


print "Load table test.dbf\n";
my $table = new XBase("$dir/test");
print XBase->errstr(), 'not ' unless defined $table;
print "ok 2\n";

exit unless defined $table;	# It doesn't make sense to continue here ;-)


print "Read the records, one by one\n";
my $records_expected = join "\n",
	'0:1:Record no 1:This is a memo for record no one::19960813',
	'1:2:No 2:This is a memo for record 2:1:19960814',
	'0:3:Message no 3:This is a memo for record 3:0:19960102';
my $records = join "\n", map {
	join ":", map { defined $_ ? $_ : "" } $table->get_record($_) }
								( 0 .. 2 );
if ($records_expected ne $records)
	{ print "Expected:\n$records_expected\nGot:\n$records\nnot "; }
print "ok 3\n";


print "Get record 0 as hash\n";
my $hash_values_expected = 'undef, 19960813, 1, "Record no 1", "This is a memo for record no one", 0';
my %hash = $table->get_record_as_hash(0);
my $hash_values = join ', ',
	map { defined $_ ? ( /^\d+$/ ? $_ : qq["$_"] ) : 'undef' }
					map { $hash{$_} } sort keys %hash;
if ($hash_values_expected ne $hash_values)
	{ print "Expected:\n\@hash{ qw( @{[sort keys %hash]} ) } =\n ($hash_values_expected)\nGot:\n$hash_values\nnot "; }
print "ok 4\n";


print "Load the table rooms\n";
my $rooms = new XBase("$dir/rooms");
print XBase->errstr, 'not ' unless defined $rooms;
print "ok 5\n";


print "Check the records using read_record\n";
$records_expected = join '', <DATA>;
$records = join "\n", (map { join ':', map { defined $_ ? $_ : '' }
			$rooms->get_record($_) }
				(0 .. $rooms->last_record())), '';
if ($records_expected ne $records)
	{ print "Expected:\n$records_expected\nGot:\n$records\nnot "; }
print "ok 6\n";


print "Check the records using get_all_records\n";
my $all_records = $rooms->get_all_records('ROOMNAME', 'FACILITY');
if (not defined $all_records)
	{ print $rooms->errstr, "not "; }
else
	{
	$records = join "\n", (map { join ':', 0, @$_; } @$all_records), '';
	if ($records_expected ne $records)
		{ print "Expected:\n$records_expected\nGot:\n$records\nnot "; }
	}
print "ok 7\n";


$XBase::Base::DEBUG = 0;

print "Check if reading record that doesn't exist will produce error\n";
my (@result) = $table->get_record(3);
print "not " if @result;
print "ok 8\n";

print "Check error message\n";
my $errstr = $table->errstr();
my $errstr_expected = "Can't read record 3, there is not so many of them\n";
if ($errstr ne $errstr_expected)
	{ print "Expected: $errstr_expected\nGot: $errstr\nnot "; }
print "ok 9\n";


print <<EOF;
If all tests in this file passed, reading of the dbf data seems correct,
including the dbt memo file.
EOF


1;

__DATA__
0: None:
0:Bay  1:Main
0:Bay 14:Main
0:Bay  2:Main
0:Bay  5:Main
0:Bay 11:Main
0:Bay  6:Main
0:Bay  3:Main
0:Bay  4:Main
0:Bay 10:Main
0:Bay  8:Main
0:Gigapix:Main
0:Bay 12:Main
0:Bay 15:Main
0:Bay 16:Main
0:Bay 17:Main
0:Bay 18:Main
0:Mix A:Audio
0:Mix B:Audio
0:Mix C:Audio
0:Mix D:Audio
0:Mix E:Audio
0:ADR-Foley:Audio
0:Mach Rm:Audio
0:Transfer:Audio
0:Bay 19:Main
0:Dub:Main
0:Flambe:Audio
0:FILM 1:Film
0:FILM 2:Film
0:FILM 3:Film
0:SCANNING:Film
0:Mix F:Audio
0:Mix G:Audio
0:Mix H:Audio
0:BullPen:Film
0:Celco:Film
0:MacGrfx:Main
0:Mix J:Audio
0:AVID:Main
0:BAY 7:Main
0::
