package main;

use strict;
use warnings;

use Test::More 0.88;

BEGIN {
    eval {
	require Test::Pod::Coverage;
	Test::Pod::Coverage->VERSION(1.00);
	Test::Pod::Coverage->import();
	1;
    } or do {
	print <<eod;
1..0 # skip Test::Pod::Coverage 1.00 or greater required.
eod
	exit;
    };
}

# The following egregious hack is to cause Date::Manip::Date subroutines
# to be counted as covered. It is unlikely to do anything useful if the
# code is actually executed.

require Date::ManipX::Almanac::Date;

local @Date::ManipX::Almanac::Date::ISA = (
    @Date::ManipX::Almanac::Date::ISA, 'Date::Manip::Date' );

all_pod_coverage_ok ({
	also_private => [ qr{^[[:upper:]\d_]+$}, ],
	coverage_class => 'Pod::Coverage::CountParents'
    });

1;

# ex: set textwidth=72 :
