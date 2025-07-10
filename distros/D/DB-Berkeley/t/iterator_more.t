use strict;
use warnings;
use Test::Most;

BEGIN { use_ok('DB::Berkeley') }

my $file = "test_iterator.bdb";
unlink $file;

my $db = DB::Berkeley->new($file, 0, 0666);
ok($db, 'DB created');

# Populate database
my %expected = (
	apple  => 'fruit',
	carrot => 'vegetable',
	salmon => 'fish',
);

foreach my $k (keys %expected) {
	ok($db->put($k, $expected{$k}), "put($k) succeeded");
}

# --- values()
my $values = $db->values;
ok(ref($values) eq 'ARRAY', "values() returned an arrayref");
cmp_bag($values, [ values %expected ], "values() returned correct values");

# --- keys()
my $keys = $db->keys;
ok(ref($keys) eq 'ARRAY', "keys() returned an arrayref");
cmp_bag($keys, [ keys %expected ], "keys() returned correct keys");

# --- each()
my %seen;
while (my $pair = $db->each()) {
	ok(ref($pair) eq 'ARRAY', "each() item is arrayref");
	my ($k, $v) = @$pair;
	$seen{$k} = $v;
}
cmp_deeply(\%seen, \%expected, "each() returned all key-value pairs");

# --- next_key() with iterator_reset
$db->iterator_reset();
my @iter1;
while (defined(my $key = $db->next_key)) {
	push @iter1, $key;
}
cmp_bag(\@iter1, [ keys %expected ], "next_key() returned all keys after reset");

# Run again to ensure iterator_reset works repeatedly
$db->iterator_reset;
my @iter2;
while (defined(my $key = $db->next_key)) {
	push @iter2, $key;
}
cmp_bag(\@iter2, [ keys %expected ], "iterator_reset + next_key() consistent");

done_testing();

END {
	unlink $file if -e $file;
}
