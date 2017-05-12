use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok('Algorithm::RandomMatrixGeneration') };

# expected matrix 
my @expected = qw (10.1899 2.4357 0.1198 0.2646 2.9373 4.3689 1.6020 2.0918 1.7620 2.6271 4.6497 3.9612 4.9395 1.9305 2.4624 3.6676 2.9623 8.6504 0.3734 0.0139 0.2140 11.9924 0.7927 0.0009);

# given row and column marginals
my @rmar = (13.01,11,13,13,12,13);
my @cmar = (23.005,32.005,10,10);

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
