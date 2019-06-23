
#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = 0.01;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More;
use Test::Number::Delta within => 1e-2;

BEGIN {
	use_ok( 'Astro::Montenbruck::Time::DeltaT', qw/delta_t/  );
}



my @cases = (
    [-102146.5, 119.51, 'historical start'], # 1620-05-01
    [-346701.5, 1820.325, 'after 948'], # 950-10-01
    [44020.5, 93.81, 'after 2010'], # 2020-07-10
    [109582.5, 407.2, 'after 2100'], # ?
);

for (@cases) {
    my ($djd, $exp, $msg) = @$_;
    my $jd = $djd + 2415020;
    my $got = delta_t($jd);
    delta_ok($got, $exp, $msg);  
}

done_testing();
