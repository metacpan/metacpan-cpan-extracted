#!perl -T
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 10;
use Test::Deep;

use Conf::Libconfig;

my $cfgfile = "./t/spec.cfg";
my $foo = Conf::Libconfig->new;
ok($foo->read_file($cfgfile), "read file - status ok");

# Check array method
cmp_deeply(
	[$foo->fetch_array("me.mar.float")],
	[
		[
			num(3.1415926535, 1e-10)
		]
	],
	"fetch scalar into array reference - status ok",
);

cmp_deeply(
	[$foo->fetch_array("me.mar.family")],
	[
		[ 123, 456, 789, 0x111, 0, "xyz",
			[ 5, 2, 13 ], [ num(43434.00001,1e-5), "abcd", 12355666 ],
			{ ok => "hello, world", b => [ 456, 0x456, 0 ] }
			]
	],
	"fetch array into array reference - status ok",
);

cmp_deeply(
	[$foo->fetch_array("me.mar.check1")],
	[
		[
			{
				'x' => 32,
				'm' => [ 1, 2, 332 ],
				'n' => [ 'a', 'b', 'c' ],
				'ooo' => [ 'this is world', ' now', 19821002 ],
				'hhh' => {
					'y' => '1000200300',
					'z' => [ 'new', ' paper' ]
				},
				'ggg' => [ 1, 96, '1234567890', 
							[ 1, 2, 3 ],
							{ 'xyz' => 1 }
				],
			}
		]
	],
	"fetch group into array reference - status ok",
);

cmp_deeply(
	[$foo->fetch_array("me.mar.check2")],
	[ [ { } ] ],
	"fetch empty group into array reference - status ok",
);

# Check hash method
cmp_deeply(
	$foo->fetch_hashref("me.mar.many"),
	{
	
	   many =>	"ok, i have",
	},
	"fetch scalar into hash reference - status ok",
);

cmp_deeply(
	$foo->fetch_hashref("me.arr"),
	{
		arr => [ "123", "abc" ]
	},
	"fetch array into hash reference - status ok",
);

cmp_deeply(
	$foo->fetch_hashref("me.emptyarray"),
	{
		emptyarray => [ ]
	},
	"fetch empty array into hash reference - status ok",
);

cmp_deeply(
	$foo->fetch_hashref("me.mar.check"),
	{
		main => [ 1, 2, 3, 4 ],
		family => [
		 [ "abc", 123, 1 ], num(1.234, 1e-4), [],
		 [ 1, 2, 3 ], { a => [ 1, 2, 1 ] }
		]
	},
	"fetch group into hash reference - status ok",
);

cmp_deeply(
	$foo->fetch_hashref("me.mar.check2"),
	{ },
	"fetch empty group into hash reference - status ok",
);

