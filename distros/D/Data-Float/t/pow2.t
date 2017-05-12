use warnings;
use strict;

use Test::More tests => 25;

BEGIN { use_ok "Data::Float", qw(
	pow2 mult_pow2
	min_finite_exp max_finite_exp
); }

ok pow2(0) == 1.0;
ok pow2(1) == 2.0;
ok pow2(5) == 32.0;
ok pow2(-1) == 0.5;
ok pow2(-5) == 0.03125;
ok pow2(max_finite_exp) != 0;
eval { pow2(max_finite_exp+1); }; like $@, qr/\Aexponent [^ \n]+ out of range/;
ok pow2(min_finite_exp) != 0;
eval { pow2(min_finite_exp-1); }; like $@, qr/\Aexponent [^ \n]+ out of range/;

sub zpat($) { my($z) = @_; my $nz = -$z; sprintf("%+.f%+.f%+.f",$z,$nz,-$nz) }
foreach(0, +0.0, -0.0) {
	my $z = $_;
	my $m = mult_pow2($z, 5);
	is zpat($z), zpat($_);
	is zpat($m), zpat($_);
	ok $m == 0;
}

ok mult_pow2(1.5, -2) == 0.375;
ok mult_pow2(-1.5, -2) == -0.375;
ok mult_pow2(1025.0, -10) == 1.0009765625;
ok mult_pow2(1.0009765625, 10) == 1025.0;
ok mult_pow2(0.5, max_finite_exp+1) == pow2(max_finite_exp);
ok mult_pow2(2.0, min_finite_exp-1) == pow2(min_finite_exp);

1;
