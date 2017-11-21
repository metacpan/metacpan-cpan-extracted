#!perl

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";

use Crypt::DRBG::Hash;
use IO::Handle;
use Test::More;

require Math::BigInt;
eval { Math::BigInt->import(try => 'GMP') };

my $obj = Crypt::DRBG::Hash->new(seed => '');
my $len = $obj->{seedlen};

my $all_zeros = "\x00" x $len;
my $all_ones = "\xff" x $len;
my $one = "\x00" x ($len-1) . "\x01";
compare_add($all_ones, $one, "wraps around properly");
compare_add($all_ones, pack('N*', 1), "int wraps around properly");

# Fractional parts of natural logs of 2, 3, 4, … with dc -l and 50k.
my @lns = qw/
	B17217F7D1CF79ABC9E3B39803F2F6AF40F3432670A1778380
	193EA7AAD030A976A4198D55053B7CB5BE1442D9B4574213FD
	62E42FEFA39EF35793C7673007E5ED5E81E6864CE500BE505B
	9C041F7ED8D336AFDF77A516075931F4494C70C0F3FB914D3C
	CAB0BFA2A20023226DFD40ED092E7364FF07860028B688E0D7
/;

my $cnt = 0;
foreach my $xh (@lns) {
	my $x = hex_to_bin($xh);
	foreach my $yh (@lns) {
		my $y = hex_to_bin($yh);
		compare_add($x, $y, "addition of $xh and $yh");
	}
	compare_add($x, pack('N*', $cnt++), "addition of $xh and an integer");
}

done_testing();

sub hex_to_bin {
	my $val = shift;
	return "\x00" x ($len - length($val) / 2) . pack('H*', $val);
}

sub compare_add {
	my ($x, $y, $msg) = @_;
	my $z = add($x, $y);
	my $res = $obj->_add($x, $y);
	return compare($res, $z, $msg);
}

sub compare {
	my ($x, $y, $msg) = @_;
	is(length($x), $len, "length of x is correct");
	is(length($y), $len, "length is y correct");
	return is(unpack("H*", $x), unpack("H*", $y), $msg);
}

# This is a known good, if slow, implementation.
sub add {
	my ($x, $y) = @_;
	my $final = Math::BigInt->bzero;
	foreach my $val ($x, $y) {
		$final += Math::BigInt->new("0x" . unpack("H*", $val));
	}
	$final &= ((Math::BigInt->bone << ($len * 8)) - 1);
	my $data = substr($final->as_hex, 2);
	$data = "0$data" if length($data) & 1;
	$data = pack("H*", $data);
	return ("\x00" x ($len - length($data))) . $data;
}
