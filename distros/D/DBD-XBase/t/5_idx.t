#!/usr/bin/perl -w

use strict;

END {
	print "not ok 1\n" unless $::XBaseloaded;
}
BEGIN {
	$| = 1;
	print "1..6\n";
	print "Load modules: use XBase; use XBase::Index;\n";
}

use XBase;
use XBase::Index;
$::XBaseloaded = 1;
print "ok 1\n";

my $dir = ( -d "t" ? "t" : "." );

$XBase::Base::DEBUG = 1;        # We want to see any problems

unlink "$dir/tstidx.dbf", "$dir/tstidxid.idx", "$dir/tstidxname.idx";

my $table = create XBase('name' => "$dir/tstidx.dbf",
	'field_names' => [ 'ID', 'NAME' ],
	'field_types' => [ 'N', 'C' ],
	'field_lengths' => [ 6, 100 ],
	'field_decimals' => [ 0, undef ]) or do {
	print XBase->errstr, "not ok 2\n";
	exit;
};

print "ok 2\n";

my $i = 0;
$table->set_record($i++, 56, 'Padesat sest');
$table->set_record($i++, 123, 'Stodvacettri');
$table->set_record($i++, 9, 'Krtek');
$table->set_record($i++, 88, 'Osmaosmdesat');
$table->set_record($i++, -7, 'minus sedm');
$table->set_record($i++, 7, 'plus sedm');
$table->set_record($i++, 15, 'Patnact');
$table->set_record($i++, -1000, 'Tisic pod nulou');

my $numindex = create XBase::idx($table, "$dir/tstidxid.idx", "id");
if (not defined $numindex) {
	print XBase->errstr, 'not ';
}
print "ok 3\n";

my $got = '';
$numindex->prepare_select;
while (my ($key, $num) = $numindex->fetch) {
	$got .= "$key $num\n";
}
my $expected = '';
while (<DATA>) {
	last if $_ eq "__END_DATA__\n";
	$expected .= $_;
}

if ($got ne $expected) {
	print "Expected:\n$expected\nGot:\n$got\nnot ";
}
print "ok 4\n";


my $charindex = create XBase::idx($table, "$dir/tstidxname.idx", "name");
if (not $charindex) {
	print XBase->errstr, 'not ';
}
print "ok 5\n";

$got = '';
$charindex->prepare_select;
while (my ($key, $num) = $charindex->fetch) {
	$key =~ s/\s+$//;
	$got .= "$key $num\n";
}
$expected = '';
while (<DATA>) {
	last if $_ eq "__END_DATA__\n";
	$expected .= $_;
}

if ($got ne $expected) {
	print "Expected:\n$expected\nGot:\n$got\nnot ";
}
print "ok 6\n";


__DATA__
-1000 8
-7 5
7 6
9 3
15 7
56 1
88 4
123 2
__END_DATA__
Krtek 3
Osmaosmdesat 4
Padesat sest 1
Patnact 7
Stodvacettri 2
Tisic pod nulou 8
minus sedm 5
plus sedm 6
