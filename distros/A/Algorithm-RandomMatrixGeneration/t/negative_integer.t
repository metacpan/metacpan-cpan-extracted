use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok('Algorithm::RandomMatrixGeneration') };

# expected matrix 
my @expected = ('-1','3','-5','-2','5','0','0','0','-2','0','3','-4');

# given row and column marginals
my @rmar = ('-5','5','-3');
my @cmar = ('2','3','-2','-6');

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
			else
			{
				push @tmp, 0;
			}
		}
	}	

is_deeply(\@tmp, \@expected, "Verified generated array - OK.");

__END__
