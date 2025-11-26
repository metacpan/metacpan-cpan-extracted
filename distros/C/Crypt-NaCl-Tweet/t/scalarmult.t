use strict;
use warnings;
use Test::More;
use Crypt::NaCl::Tweet ':scalarmult';

# randomly generated/pre-calculated
# bad_* has first or last nybble modified
my $n1 = pack('H*', '2c5980c99453d858f5d139e2c7403749487152a233595ebea0da6c53cf51d7b0');
my $bad_n1 = pack('H*', '4c5980c99453d858f5d139e2c7403749487152a233595ebea0da6c53cf51d7b0');
my $p1 = pack('H*', '5f0ef941fdb49288f8971a6cb967c6f15645582d90e3ce36ba65dda925b9f23d');
my $bad_p1 = pack('H*', '5f0ef941fdb49288f8971a6cb967c6f15645582d90e3ce36ba65dda925b9f23e');
my $n2 = pack('H*', 'f992a7f02d21c73a2200b02ad34f9b6fd986e2d86e7d24fc6feeffe1ed3ffbae');
my $p2 = pack('H*', 'd6229e79f9c7a9ffc594195ee9b6e911aa8229bd7a8b8c839e737ade0a12280e');

my $q = scalarmult_base($n1);
ok($q, "scalarmult_base generates output");
is(length($q), scalarmult_BYTES, "scalarmult_base correct output length");
is($q, $p1, "scalarmult_base generates correct element");
isnt(scalarmult_base($bad_n1), $p1, "scalarmult_base incorrect scalar doesn't generate correct element");

is(scalarmult($n1, $p2), scalarmult($n2, $p1), "scalarmult equiavalence");
isnt(scalarmult($bad_n1, $p2), scalarmult($n2, $p1), "scalarmult incorrect scalar doesn't match");
isnt(scalarmult($n1, $p2), scalarmult($n2, $bad_p1), "scalarmult incorrect element doesn't match");

done_testing();
