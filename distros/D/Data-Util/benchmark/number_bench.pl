#!perl -w

use strict;
use Benchmark qw(:all);

use Scalar::Util qw(looks_like_number);
use Data::Util qw(:all);

use FindBin qw($Bin);
use lib $Bin;
use Common;

signeture
	'Data::Util' => \&is_number,
	'Scalar::Util' => \&looks_like_number;

print "Benchmark: is_number(), is_integer(), looks_like_number()\n";
for my $x(42, exp(1), '42', sprintf('%g', exp(1)), undef){
	print "For ", neat($x), "\n";

	cmpthese -1 => {
		is_number => sub{
			for(1 .. 100){
				my $ok = is_number $x;
			}
		},
		is_integer => sub{
			for(1 .. 100){
				my $ok = is_integer $x;
			}
		},
		looks_like_number => sub{
			for(1 .. 100){
				my $ok = looks_like_number $x;
			}
		},
	};
	print "\n";
}
