use Algorithm::Networksort;

my $inputs = $ARGV[0] || 5;
my $cmptrcount = $ARGV[1] || $inputs * 2;
my @network = ([0,1]) x $cmptrcount;
my $combinations = (($inputs * ($inputs - 1))/2)**$cmptrcount;
my $start_at = $ARGV[2] || 0;

print "N = $inputs, searching for a sort using $cmptrcount comparators.\nNumber of possible combinations: $combinations\n\n";

my $nw;

#
# Skip over the ones we're not starting with.
#
for (my $j = 0; $j < $start_at; $j++)
{
	@network = next_network(\@network, $inputs, $cmptrcount);
}

for (my $j = $start_at; $j < $combinations; $j++)
{
	@network = next_network(\@network, $inputs, $cmptrcount);
	$nw = nwsrt(inputs => $inputs, algorithm => 'none',
			comparators => [@network],
			title => sprintf("%08d: ", $j) . "$inputs Inputs"
		);

	print STDERR $nw->title(), $nw->formatted(), "\n" if (($j % 1000) == 0);

	if (zero_one($nw) eq 'pass')
	{
		print "Solved! at $j of $combinations.\n";
		last;
	}
}

print $nw->title(), "\n", $nw, "\n";

print $nw->graph_text();

exit(0);

sub comp_incr
{
	my($from, $to, $inputs) = @_;
	$to++;
	if ($to == $inputs)
	{
		$from++;
		return (0,1) if ($from == $inputs - 1);
		return ($from, $from+1);
	}
	return ($from, $to);
}

sub next_network
{
	my $network_ref = shift;
	my $inputs = shift;
	my $n_comps = shift;
	
	for (my $j = $n_comps - 1; $j >= 0; $j--)
	{
		my $comparator = $$network_ref[$j];
		my($from, $to) = comp_incr(@$comparator, $inputs);
		$$network_ref[$j] = [$from, $to];
		return @$network_ref unless ($from == 0 && $to == 1);
	}
	return @$network_ref;
}

#
# Test using all binary combinations.  (Skipping the all-zeros
# and all-ones cases, which are already pretty well sorted).
#
sub zero_one
{
	my $nw = shift;
	my $zo = qr/^0+1+$/;

	foreach my $x (1 .. (1 << $nw->inputs()) - 2)
	{
		my @bitlist = (split(//, unpack("B32", pack("N", $x))))[32 - $nw->inputs() .. 31];
		my $x_binary = join "", @bitlist;

		next if ($x_binary =~ $zo);	# An already-sorted sequence.

		$nw->sort(\@bitlist);

		my $sort_string = join "", @bitlist;

		return "'$x_binary' ($x) sorted to '$sort_string'." unless ($sort_string =~ $zo);
	}

	return "pass";
}

