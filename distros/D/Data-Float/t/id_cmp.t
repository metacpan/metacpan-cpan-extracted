use warnings;
use strict;

use Test::More tests => 1 + 2*9*9 + 8*9;

BEGIN { use_ok "Data::Float", qw(
	have_infinite have_signed_zero have_nan float_id_cmp totalorder
); }

no strict "refs";
my @values = (
	sub { have_nan ? &{"Data::Float::nan"} : undef },
	sub { have_infinite ? &{"Data::Float::neg_infinity"} : undef },
	-1000.0,
	-0.125,
	sub { have_signed_zero ? &{"Data::Float::neg_zero"} : undef },
	+0.0,
	+0.125,
	+1000.0,
	sub { have_infinite ? &{"Data::Float::pos_infinity"} : undef },
);

foreach(@values) {
	$_ = $_->() if ref($_) eq "CODE";
}

sub zpat($) { my($z) = @_; my $nz = -$z; sprintf("%+.f%+.f%+.f",$z,$nz,-$nz) }

for(my $ia = @values; $ia--; ) {
	for(my $ib = @values; $ib--; ) {
		SKIP: {
			my($a, $b) = @values[$ia, $ib];
			my $az = $ia == 4 || $ia == 5 ? 1 : 0;
			my $bz = $ib == 4 || $ib == 5 ? 1 : 0;
			skip "special value not available", 2*(1+$az+$bz)
				unless defined($a) && defined($b);
			my($ta, $tb) = ($a, $b);
			is float_id_cmp($ta, $tb), ($ia <=> $ib);
			is zpat($ta), zpat($a) if $az;
			is zpat($tb), zpat($b) if $bz;
			($ta, $tb) = ($a, $b);
			is !!totalorder($ta, $tb), ($ia <= $ib);
			is zpat($ta), zpat($a) if $az;
			is zpat($tb), zpat($b) if $bz;
		}
	}
}

1;
