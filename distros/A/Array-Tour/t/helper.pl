#!usr/bin/perl
#
# helper.pl
#
use Array::Tour qw(:directions);
my @b36_seq = ('0'..'9', 'A'..'Z', 'a'..'z');

sub makegrid
{
	my $tour = shift;
	my($width, $height) = $tour->get_dimensions();

	my @grid = ((' ' x $width) x $height);
	my $ctr = 0;

	while (my $cref = $tour->next())
	{
		my @coords = @{$cref};
		substr($grid[$coords[1]], $coords[0], 1) = $b36_seq[$ctr];
		$ctr = ($ctr + 1) % (scalar @b36_seq);
	}
	return @grid;
}

1;
