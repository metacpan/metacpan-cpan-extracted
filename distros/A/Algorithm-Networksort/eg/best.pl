use Algorithm::Networksort ':all';
use Algorithm::Networksort::Best ':all';
use strict;
use warnings;

my $inputs;
my $name;

if (@ARGV == 0)
{
	warn "best.pl <input size>\nbest.pl <key name>\n\nPlease give an input size or a key name.";
	exit(0);
}

if ($ARGV[0] =~ /^[0-9]+/)
{
	$inputs = $ARGV[0];
	my(@names) = nw_best_names($inputs);
	if (@names == 0)
	{
		print "No 'best' networks available for size $inputs.\n";
		exit(0);
	}

	print "Available names for size $inputs: ", join(", ", @names), "\n";
	exit(0);
}

$name = $ARGV[0] || die "Please use a keyname or a number.";

my $nw = nwsrt_best(name => $name);

print $nw;

exit(0);
