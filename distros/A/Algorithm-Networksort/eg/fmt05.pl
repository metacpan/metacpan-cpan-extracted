use Algorithm::Networksort;
use strict;
use warnings;

my $inputs = $ARGV[0] || 8;
my $alg = $ARGV[1] || 'hibbard';

my $nw = Algorithm::Networksort->new(inputs => $inputs, algorithm => $alg);
my @alphabase = ('a'..'z')[0..$inputs];
$nw->index_base(\@alphabase);
$nw->formats(["[%s, %s],"]);

my $string = '[' .  $nw->formatted();

substr($string, -1, 1) = ']';
print $string;

exit(0);
