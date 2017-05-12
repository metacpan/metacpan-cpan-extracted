#$Id: 02_amb.t,v 1.2 2008/07/07 11:22:44 dk Exp $
use strict;
use warnings;

use Test::More tests => 7;

use Amb;

my $g = 0;
if ( amb(1,0)) {
	$g += 5;
	die;
} else {
	$g--;
}
ok($g == 4, 'die main');

sub x
{
	$g = 0;
	if ( amb(1,0)) {
		$g += 5;
		die;
	} else {
		$g--;
	}
}
x();
ok($g == 4, 'die insub');

$g = 0;
if (amb(0,1)) {
	$g += 5;
	die;
} else {
	$g--;
}
ok($g == -1, 'nodie main');

sub x2
{
	$g = 0;
	if ( amb(0,1)) {
		$g += 5;
		die;
	} else {
		$g--;
	}
}
x2();
ok($g == -1, 'nodie insub');

#
$g = 0;
if ( amb(1,0)) {
	$g += 5;
	if ( amb(1,0)) {
		$g += 5;
		die;
	} else {
		$g--;
	}
} else {
	$g--;
}
ok($g == 9, 'nested');

# eval
$g = 0;
if ( amb(1,0)) {
	eval { 
		die;
	};
	$g++;
}
ok( $g == 1, 'eval');

# recursive
$g = 0;
my $depth = 0;
sub x3
{
	if ( amb(1,0)) {
		if ($depth) {
			$g += 10;
			die;
			$g += 10;
		} else {
			$depth++;
			$g += 100;
			x3();
			$g += 100;
		}
	} else {
		$g++;
		$g+= $depth * 3;
	}
}
x3();
ok( $g == 214, 'recursive');
