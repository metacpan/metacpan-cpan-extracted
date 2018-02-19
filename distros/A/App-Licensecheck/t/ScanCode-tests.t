#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::Licensecheck::ScanCode tests => 1434;

# work around ScanCode not distinguishing explicitly ORed licenses
# https://github.com/nexB/scancode-toolkit/issues/929
#<<<  [ avoid perltidy rewrapping these ]
my $overrides;
$overrides->{'apache-2.0_and_bsd-new_and_gpl-2.0-plus_and_lgpl-2.1-plus_and_mpl-1.1_and_other'}
	= [ 'Apache-2.0', 'BSD-3-Clause', 'GPL-2+ or LGPL-2.1+', 'MPL-1.1', 'MS-PL' ];
$overrides->{'apache-2.0_and_gpl-2.0'}
	= ['Apache-2.0 or GPL-2'];
$overrides->{'gpl-2.0-plus_and_gpl-2.0-plus_and_lgpl-2.1-plus_and_mpl-1.1_and_other'}
	= [ 'GPL-2+ or LGPL-2.1+', 'MPL-1.1' ];
$overrides->{'gpl-2.0-plus_and_lgpl-2.1-plus_and_mpl-1.1'}
	= [ 'GPL-2+ or LGPL-2.1+', 'MPL-1.1' ];
#>>>

are_licensed_like_scancode(
	[qw(tests/licensedcode/data/licenses)],
	't/ScanCode-tests.todo', $overrides
);

done_testing;
