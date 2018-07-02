use Getopt::Long;
use Algorithm::Networksort;
use Algorithm::Networksort::Best qw(:all);

use strict;
use warnings;

my %txtset = (compbegin => undef,
	compend => undef,
	compline => undef,
	inputbegin => undef,
	inputend => undef,
	inputline => undef,
);
my $alg = 'bosenelson';
my($nw, $best);

GetOptions(
	'compbegin=s' => \$txtset{compbegin},
	'compend=s' => \$txtset{compend},
	'compline=s' => \$txtset{compline},
	'inputbegin=s' => \$txtset{inputbegin},
	'inputend=s' => \$txtset{inputend},
	'inputline=s' => \$txtset{inputline},
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

#
# Ensure we're only passing in set parameters. And, if it's defined
# (and because it's a pain to do it on the command line), fix the endline.
#
my %def_txtset;
for (keys %txtset)
{
	$def_txtset{$_} = $txtset{$_} if (defined $txtset{$_})
}

$def_txtset{inputend} .= "\n" if (defined $txtset{inputend});

$nw->textsettings(%def_txtset);

print $nw->graph_text() . "\t" . $nw->title() . "\n";

exit(0);
