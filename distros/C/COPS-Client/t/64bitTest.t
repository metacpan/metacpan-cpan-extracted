#!perl -T

use Test::More tests => 1;
use Config;

SKIP:
        {
	if (!$Config{'use64bitint'})
		{
		skip "1..0 # Skip: Perl not compiled with 'use64bitint'\n",1;
		}
	$tester=576466952313524498;
	$origin = $tester;
	print "Tester is '$tester'\n";
	my($test1) = $tester & 0xFFFFFFFF; $tester >>= 32;
	my($test2) = $tester & 0xFFFFFFFF;
	$message = pack("NN",$test2,$test1);
	($part1,$part2) = unpack("NN",$message);
	$part1 = $part1<<32;
	$part1+=$part2;
	print "Tester is '$tester' part1 is '$part1'\n";
	if ( $origin!=$part1 )
		{
		fail("Perl does not support 64bit numbers, '$origin' '$part1' (htf did we get here ?)");
		}
		else
		{
		pass("64Bit support enabled");
		}
	}

