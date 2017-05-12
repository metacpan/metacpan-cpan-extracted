use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Carp;

$SIG{__DIE__} = sub { confess @_; };

my $add_tests;
my $overlap_tests;
my $mixed_tests;
my $remove_tests;
my $mixed_dup_tests;

BEGIN {
	$add_tests = 5;
	$overlap_tests = 5;
	$mixed_tests = 5;
	$remove_tests = 5;
	$mixed_dup_tests = 5;

	plan tests => 20 +
		2  * $add_tests +
		2  * $overlap_tests +
		20 * $mixed_tests +
		10 * $remove_tests +
		20 * $mixed_dup_tests;
}

use_ok('Cache::File::Heap');

my $tempdir = tempdir(CLEANUP => 1);

my $dbfile = File::Spec->catfile($tempdir, 'test.db');
my $heap = Cache::File::Heap->new($dbfile);
ok($heap, "Heap created ($dbfile)");

# Test basic add and extract
my $val = 'Some data to go in the heap';
my $key = 1053523491;
eval { $heap->add($key, $val) };
ok(!$@, 'Entry added');

my $mkey = $heap->minimum;
ok($mkey, 'Minimum returned');
is($mkey, $key, 'Minimum key correct');

my ($okey, $oval) = $heap->extract_minimum();
is($okey, $key, 'Key of entry extracted');
is($oval, $val, 'Value of entry extracted');


# Test multiple add and extract

for (1..$add_tests) {
	$heap->add($_, "Test entry $_");
}

$mkey = $heap->minimum;
is($mkey, 1, 'Minimum key correct');

undef $heap;
$heap = Cache::File::Heap->new($dbfile);
ok($heap, "Heap reopened ($dbfile)");

my $i = 1;
for (1..$add_tests) {
	($okey, $oval) = $heap->extract_minimum();
	is($okey, $_, "Key of min entry $_ correct ($i)");
	is($oval, "Test entry $_", "Value of min entry $_ correct ($i)");
	$i++;
}

is($heap->minimum, undef, 'Heap empty');


# Test multiple identical keys

for (1..$overlap_tests) {
	$heap->add($key, "Test overlap entry $_");
}

$heap->close();
ok($heap->open($dbfile), "Heap reopened ($dbfile)");

$mkey = $heap->minimum;
is($mkey, $key, 'Minimum key correct');

$i = 1;
for (1..$overlap_tests) {
	($okey, $oval) = $heap->extract_minimum();
	is($okey, $key, "Key of min overlap entry $_ correct ($i)");
	like($oval, qr/^Test overlap entry \d+$/,
		"Value of min overlap entry $_ correct ($i)");
	$i++;
}

is($heap->minimum, undef, 'Heap empty');


# Test mixed keys

for (1..$mixed_tests) {
	$heap->add($_, "Test entry $_ : 1");
}
for (1..$mixed_tests) {
	my $skey = $_;
	for (2..5) {
		$heap->add($skey, "Test entry $skey : $_");
	}
}
for (1..$mixed_tests) {
	my $skey = $_;
	for (6..10) {
		$heap->add($skey, "Test entry $skey : $_");
	}
}

$mkey = $heap->minimum;
is($mkey, 1, 'Minimum key correct');

undef $heap;
$heap = Cache::File::Heap->new($dbfile);
ok($heap, "Heap reopened ($dbfile)");

$i = 1;
for my $skey (1..$mixed_tests) {
	for (1..10) {
		($okey, $oval) = $heap->extract_minimum();
		is($okey, $skey,
			"Key of min mixed entry $skey: $_ correct ($i)");
		like($oval, qr/^Test entry $skey : \d+$/,
			"Value of min mixed entry $skey : $_ correct ($i)");
		$i++;
	}
}

is($heap->minimum, undef, 'Heap empty');


# Test remove of items

my @data;
for (1..$remove_tests) {
	my $skey = $_;
	my $sval = "Test entry $skey : 1";
	$heap->add($skey, $sval);
	push(@data, [$skey, $sval]);
}
for (1..$remove_tests) {
	my $skey = $_;
	for (2..5) {
		my $sval = "Test entry $skey : $_";
		$heap->add($skey, $sval);
		push(@data, [$skey, $sval]);
	}
}
for (1..$remove_tests) {
	my $skey = $_;
	for (6..10) {
		my $sval = "Test entry $skey : $_";
		$heap->add($skey, $sval);
		push(@data, [$skey, $sval]);
	}
}

undef $heap;
$heap = Cache::File::Heap->new($dbfile);
ok($heap, "Heap reopened ($dbfile)");

# shuffle data
$i = @data;
while ($i--) {
	my $j = int rand ($i+1);
	@data[$i,$j] = @data[$j,$i];
}

$i = 1;
foreach (@data) {
	my ($skey, $sval) = @$_;
	ok($heap->delete($skey, $sval), "Entry removed for $skey ($i)");
	$i++;
}

is($heap->minimum, undef, 'Heap empty');


# Test extraction of dups

for (1..$mixed_dup_tests) {
	$heap->add($_, "Test entry $_ : 1");
}
for (1..$mixed_dup_tests) {
	my $skey = $_;
	for (2..5) {
		$heap->add($skey, "Test entry $skey : $_");
	}
}
for (1..$mixed_dup_tests) {
	my $skey = $_;
	for (6..9) {
		$heap->add($skey, "Test entry $skey : $_");
	}
}

$mkey = $heap->minimum;
is($mkey, 1, 'Minimum key correct');

$i = 1;
for my $skey (1..$mixed_dup_tests) {
	my ($okey, $ovals) = $heap->extract_minimum_dup();
	is($okey, $skey, "Key for extracted entries $skey correct");
	is(scalar @$ovals, 9, "Correct number of records extracted for $skey");
	@$ovals = sort @$ovals;
	for (1..9) {
		my $oval = shift @$ovals;
		is($okey, $skey,
			"Key of min dup entry $skey: $_ correct ($i)");
		like($oval, qr/^Test\ entry\ $skey\ :\ $_ $/x,
			"Value of min dup entry $skey : $_ correct ($i)");
		$i++;
	}
}

is($heap->minimum, undef, 'Heap empty');
