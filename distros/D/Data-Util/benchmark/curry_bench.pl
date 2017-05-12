#!perl -w

use strict;
use Data::Util qw(curry);

use FindBin qw($Bin);
use lib $Bin;
use Common;

use Benchmark qw(:all);

signeture
	'Data::Util'   => \&curry,
;

sub f{ @_ }

print "Creation:\n";
cmpthese -1 => {
	curry => sub{
		my($a, $b) = (1, 3);
		my $c = curry(\&f, $a, \0, $b, \1);
	},
	closure => sub{
		my($a, $b) = (1, 3);

		my $c = sub{ f($a, $_[0], $b, $_[1]) };
	},
};

my($a, $b) = (1, 3);
my $c = curry(\&f, $a, \0, $b, \1);
my $d = sub{ f($a, $_[0], $b, $_[1]) };

print "Calling with subscriptive placeholders:\n";
cmpthese -1 => {
	curry => sub{
		$c->(2, 4) == 4 or die;
	},
	closure => sub{
		$d->(2, 4) == 4 or die;
	},
};

$c = curry(\&f, $a, *_, $b);
$d = sub{ f($a, @_[0 .. $#_], $b) };

print "Calling with the symbolic placeholder:\n";
cmpthese -1 => {
	curry => sub{
		$c->(1 .. 5) == 7 or die $c->(1 .. 5);
	},
	closure => sub{
		$d->(1 .. 5) == 7 or die $d->(1 .. 5);
	},
};
	
