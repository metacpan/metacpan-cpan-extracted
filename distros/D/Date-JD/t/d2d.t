use warnings;
use strict;

use Test::More tests => 1 + 26*2*8*8*4;

BEGIN { use_ok "Date::JD", qw(jd_to_jd jd_to_mjdnf mjdn_to_cjd cjdn_to_ldn); }

my $have_bigrat = eval("use Math::BigRat 0.13; 1");

sub match($$) {
	my($a, $b) = @_;
	ok ref($a) eq ref($b) && $a == $b;
}

my @prep = (
	sub { $_[0] },
	sub { $have_bigrat ? Math::BigRat->new($_[0]) : undef },
);

my %zoneful = (
	jd => 0,
	rjd => 0,
	mjd => 0,
	djd => 0,
	tjd => 0,
	cjd => 1,
	rd => 1,
	ld => 1,
);

sub flr($) {
	my($n) = @_;
	if(ref($n) eq "Math::BigRat") {
		return $n->copy->bfloor;
	} else {
		my $i = int($n);
		return $i == $n || $n > 0 ? $i : $i - 1;
	}
}

sub check($$) {
	my($dates, $zone) = @_;
	foreach my $src (keys %$dates) { foreach my $dst (keys %$dates) {
		my $sd = $dates->{$src};
		my $dd = $dates->{$dst};
		my @zone = $zoneful{$src} == $zoneful{$dst} ? () : ($zone);
		foreach my $prep (@prep) { SKIP: {
			my $psd = $prep->($sd);
			my $pdd = $prep->($dd);
			skip "numeric type unavailable", 26
				unless defined($psd) && defined($pdd);
			my $func = \&{"Date::JD::${src}_to_${dst}"};
			my $r = $func->($psd, @zone);
			match $r, $pdd;
			my @r = $func->($psd, @zone);
			is scalar(@r), 1;
			match $r[0], $pdd;
			$func = \&{"Date::JD::${src}_to_${dst}nn"};
			my $dn = $func->($psd, @zone);
			@r = $func->($psd, @zone);
			is scalar(@r), 1;
			match $r[0], $dn;
			$func = \&{"Date::JD::${src}_to_${dst}nf"};
			@r = $func->($psd, @zone);
			is scalar(@r), 2;
			my $dtod = $r[1];
			match $r[0], $dn;
			ok $dtod >= 0 && $dtod < 1;
			match $dn + $dtod, $pdd;
			$func = \&{"Date::JD::${src}_to_${dst}n"};
			$r = $func->($psd, @zone);
			match $r, $dn;
			@r = $func->($psd, @zone);
			is scalar(@r), 2;
			match $r[0], $dn;
			match $r[1], $dtod;
			$func = \&{"Date::JD::${src}n_to_${dst}"};
			my $psdn = flr($psd);
			my $stod = $psd - $psdn;
			$r = $func->($psdn, $stod, @zone);
			match $r, $pdd;
			@r = $func->($psdn, $stod, @zone);
			is scalar(@r), 1;
			match $r[0], $pdd;
			$func = \&{"Date::JD::${src}n_to_${dst}nn"};
			$r = $func->($psdn, $stod, @zone);
			match $r, $dn;
			@r = $func->($psdn, $stod, @zone);
			is scalar(@r), 1;
			match $r[0], $dn;
			$func = \&{"Date::JD::${src}n_to_${dst}nf"};
			@r = $func->($psdn, $stod, @zone);
			is scalar(@r), 2;
			match $r[0], $dn;
			match $r[1], $dtod;
			$func = \&{"Date::JD::${src}n_to_${dst}n"};
			$r = $func->($psdn, $stod, @zone);
			match $r, $dn;
			@r = $func->($psdn, $stod, @zone);
			is scalar(@r), 2;
			match $r[0], $dn;
			match $r[1], $dtod;
		} }
	} }
}

check({
	jd => 2453883.125,
	rjd => 53883.125,
	mjd => 53882.625,
	djd => 38863.125,
	tjd => 13882.625,
	cjd => 2453883.6875,
	rd => 732458.6875,
	ld => 154723.6875,
}, 0.0625);

check({
	jd => -7546116.875,
	rjd => -9946116.875,
	mjd => -9946117.375,
	djd => -9961136.875,
	tjd => -9986117.375,
	cjd => -7546116.3125,
	rd => -9267541.3125,
	ld => -9845276.3125,
}, 0.0625);

check({
	jd => 2403883.125,
	rjd => 3883.125,
	mjd => 3882.625,
	djd => -11136.875,
	tjd => -36117.375,
	cjd => 2403883.5625,
	rd => 682458.5625,
	ld => 104723.5625,
}, -0.0625);

check({
	jd => 2403883,
	rjd => 3883,
	mjd => 3882.5,
	djd => -11137,
	tjd => -36117.5,
	cjd => 2403883.4375,
	rd => 682458.4375,
	ld => 104723.4375,
}, -0.0625);

1;
