use warnings;
use strict;

use Test::More tests => 2;

use Devel::CallParser ();
sub tpad {
	my($a, $b, $c, $d);
	my($e, $f, $g, $h);
	my $i;
	is $i, undef;
	$i = 3;
}
tpad();
tpad();

1;
