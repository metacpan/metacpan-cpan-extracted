use strict;
use warnings;
use Test::More;
use DB::Berkeley;

my $file = 't/nested_loops.db';
unlink $file if -e $file;

my $db = DB::Berkeley->new($file, 0, 0600);

my %data = (
	apple  => 'red',
	banana => 'yellow',
	grape  => 'purple',
);

# Populate DB
while (my ($k, $v) = each %data) {
	ok($db->put($k, $v), "put $k => $v");
}

# Outer loop collects keys and values
my %outer_seen;

my $iter1 = $db->iterator;
my $iter2 = $db->iterator;

# Start outer loop
while (my $pair1 = $iter1->each()) {
	my ($k1, $v1) = @$pair1;
	$outer_seen{$k1} = $v1;

	# Start inner loop inside outer loop - should not interfere
	my %inner_seen;
	$db->iterator_reset();
	while (my $pair2 = $iter2->each()) {
		my ($k2, $v2) = @$pair2;
		$inner_seen{$k2} = $v2;
	}

	# Inner loop must see all data each time
	is_deeply(\%inner_seen, \%data, 'Inner loop sees all data on each iteration of outer');

	# Reset inner iterator
	# $iter2 = $db->iterator;
	$iter2->iterator_reset();
}

# Outer loop must also see all data
is_deeply(\%outer_seen, \%data, 'Outer loop sees all data');

done_testing();

# Clean up
END {
	unlink $file if -e $file;
}
