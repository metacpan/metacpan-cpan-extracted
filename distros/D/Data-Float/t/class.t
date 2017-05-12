use warnings;
use strict;

use Test::More tests => 1 + 8*11 + 3*8;

BEGIN { use_ok "Data::Float", qw(
	have_subnormal have_infinite have_nan
	float_class float_is_normal float_is_subnormal
	float_is_nzfinite float_is_zero float_is_finite
	float_is_infinite float_is_nan
); }

no strict "refs";
my %values = (
	NORMAL => [
		-1000.0,
		-0.125,
		+0.125,
		+1000.0,
	],
	SUBNORMAL => [ sub {
		have_subnormal ? 3.0*&{"Data::Float::min_finite"} : undef
	} ],
	ZERO => [ 0, +0.0, -0.0 ],
	INFINITE => [
		sub { have_infinite ? &{"Data::Float::neg_infinity"} : undef },
		sub { have_infinite ? &{"Data::Float::pos_infinity"} : undef },
	],
	NAN => [
		sub { have_nan ? &{"Data::Float::nan"} : undef },
	],
);

foreach(values %values) {
	foreach(@$_) {
		$_ = $_->() if ref($_) eq "CODE";
	}
}

foreach my $class (keys %values) {
	foreach(@{$values{$class}}) { SKIP: {
		skip "special value not available", 8 unless defined $_;
		my $t;
		is float_class($t = $_), $class;
		is !!float_is_normal($t = $_), $class eq "NORMAL";
		is !!float_is_subnormal($t = $_), $class eq "SUBNORMAL";
		is !!float_is_nzfinite($t = $_), !!($class =~ /NORMAL\z/);
		is !!float_is_zero($t = $_), $class eq "ZERO";
		is !!float_is_finite($t = $_), !!($class =~ /ZERO\z|NORMAL\z/);
		is !!float_is_infinite($t = $_), $class eq "INFINITE";
		is !!float_is_nan($t = $_), $class eq "NAN";
	} }
}

sub zpat($) { my($z) = @_; my $nz = -$z; sprintf("%+.f%+.f%+.f",$z,$nz,-$nz) }
foreach(\&float_class, \&float_is_normal, \&float_is_subnormal,
	\&float_is_nzfinite, \&float_is_zero, \&float_is_finite,
	\&float_is_infinite, \&float_is_nan
) {
	foreach my $z (0, +0.0, -0.0) {
		my $tz = $z;
		my $pat = zpat($tz);
		$_->($tz);
		is zpat($tz), $pat;
	}
}

1;
