use warnings;
use strict;

use Test::More tests => 45;

use IO::File 1.03;

BEGIN {
	use_ok "Data::Entropy::Source";
	use_ok "Data::Entropy", qw(with_entropy_source);
	use_ok "Data::Entropy::Algorithms", qw(rand_bits);
}

with_entropy_source +Data::Entropy::Source->new(
		IO::File->new("t/test0.entropy", "r") || die($!), "getc"
), sub {
	for(my $nbits = 1; <DATA>; $nbits++) {
		chop;
		is rand_bits($nbits), pack("h*", $_);
	}
	is rand_bits(0), "";
	eval { rand_bits(-1); };
	like $@, qr/\Aneed a non-negative number of bits to dispense/;
};

1;

__DATA__
10
00
40
e0
d0
c3
b4
aa
1710
2510
df30
f690
e050
97f1
82f2
6969
8f0600
e4ab20
392970
330480
9a0830
9104e2
e49800
799eb3
127e2710
093e3910
73224e30
b322ad60
802571c1
da60b0e0
8ef185f2
09ff56c1
dcdebc4710
e2ec56a720
b0d3a76940
cc023a1d30
ccb6bf6cc0
b77a0423d0
59f0e00911
253b85cd8d
