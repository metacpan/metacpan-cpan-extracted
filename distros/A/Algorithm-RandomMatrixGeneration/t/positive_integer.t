use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok('Algorithm::RandomMatrixGeneration') };

# expected matrix 
my @expected = qw (10 3 3 2 3 3 4 1 2 6 3 8 1 1 12 3 6 4);

# given row and column marginals
my @rmar = (13,11,13,13,12,13);
my @cmar = (23,32,10,10);

my $n = $#rmar;
my $m = $#cmar;

my @result = generateMatrix(\@rmar, \@cmar, 4, 3);

my @tmp = ();
	for(my $i=0; $i<=$n; $i++)
	{
		for(my $j=0; $j<=$m; $j++)
		{
			if(defined $result[$i][$j])
			{
				push @tmp, $result[$i][$j];
			}
		}
	}	

is_deeply(\@tmp, \@expected, "Verified generated array - OK.");

__END__
