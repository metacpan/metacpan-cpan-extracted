
#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = 0.01;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More;
use Test::Number::Delta within => 1e-6;
use Astro::Montenbruck::Time qw/jd_cent cal2jd/;

BEGIN {
	use_ok( 'Astro::Montenbruck::NutEqu', qw/mean2true obliquity deltas/  );
}

my $t = jd_cent(cal2jd(2019, 6, 2, 12, 0));

subtest 'deltas' => sub {
    plan tests => 2;

    my ($dpsi, $deps) = deltas($t);
    delta_ok(-0.0000839, $dpsi, 'delta-psi');
    delta_ok(-0.0000169, $deps, 'delta-eps');
};

subtest 'mean2true' => sub {
    plan tests => 3;

    my $f = mean2true($t);
    my ($x, $y, $z) = $f->(1, 1, 1);
    delta_ok($x, 1.0001103, 'X');
    delta_ok($y, 0.9999400, 'Y');
    delta_ok($z, 0.9999497, 'Z');
};

delta_ok(obliquity($t), 23.4367663, 'obliquity');


done_testing();
