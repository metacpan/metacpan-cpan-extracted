use Algorithm::Networksort;

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

1;
