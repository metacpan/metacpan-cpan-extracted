use Algorithm::Networksort;

#
# Basically do ad-hoc what abecedarian.t does.
#
my $inputs = $ARGV[0] || 6;
my $alg = $ARGV[1] || 'hibbard';

my $nw = nwsrt(inputs => $inputs, algorithm => $alg);

print STDERR $nw->formatted(), "\n";

print $nw->graph_text(), $nw->title(), "\n\n\n\ttesting...\n";

#
# Now test using an array of all of the binary combinations, skipping
# the all-zeros and all-ones cases which are already pretty well sorted.
#
foreach my $x (1 .. (1 << $inputs) - 2)
{
	my @bitlist = (split(//, unpack("B32", pack("N", $x))))[32 - $inputs .. 31];
	my $bitstring = join "", @bitlist;

	$nw->sort(\@bitlist);

	my $sort_bits = join "", @bitlist;

	die "Sort test fails at 0b$bitstring\n" if ($sort_bits !~ m/^0+1+$/);
}

print "Passed zero-one tests.\n";

exit(0);
