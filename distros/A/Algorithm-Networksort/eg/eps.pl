use Getopt::Long;
use Algorithm::Networksort;
use Algorithm::Networksort::Best qw(:all);

use strict;
use warnings;

my %colorset = (compbegin => undef,
	compend => undef,
	compline => undef,
	inputbegin => undef,
	inputend => undef,
	inputline => undef,
	foreground => undef,
);
my $alg = 'bosenelson';
my($nw, $best);

GetOptions('compbegin=s' => \$colorset{compbegin},
	'compend=s' => \$colorset{compend},
	'compline=s' => \$colorset{compline},
	'inputbegin=s' => \$colorset{inputbegin},
	'inputend=s' => \$colorset{inputend},
	'inputline=s'=> \$colorset{inputline},
	'foreground=s' => \$colorset{foreground},
	'algorithm=s' => \$alg,
	'best=s' => \$best,
);

my $inputs = $ARGV[0] || 8;

if (defined $best)
{
	$nw = nwsrt_best(name => $best);
}
else
{
	$nw = nwsrt(inputs => $inputs, algorithm => $alg);
}

$nw->colorsettings(%colorset);

print $nw->graph_eps();

exit(0);
