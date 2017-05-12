use Algorithm::Networksort;
use strict;
use warnings;

my $inputs = $ARGV[0] || 8;
my $alg = $ARGV[1] || 'hibbard';

my $nw = Algorithm::Networksort->new(inputs => $inputs, algorithm => $alg);

$nw->formats(["if (v[%d] < v[%d]) then\n",
	"    exchange(v, %d, %d)\nend if\n"]);
print $nw->formatted();

exit(0);
