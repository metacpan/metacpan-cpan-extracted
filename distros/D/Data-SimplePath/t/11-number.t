#!/usr/bin/perl -T

use strict;
use warnings;

use Data::SimplePath;

BEGIN {
	use Test::More;
	use Test::NoWarnings;
	use Test::Warn;
	plan ('tests' => 53);
}

# 0 must return '0 but true' [2 tests]:
is ( Data::SimplePath::_number    (0), '0 but true', '_number: 0 but true');
is ( Data::SimplePath::_is_number (0), '0 but true', '_is_number: 0 but true');

# other valid integers must be returned as they are [10 * 2 tests]:
foreach (1 .. 9, 987654321) {
	is ( Data::SimplePath::_number    ($_), $_, "$_ is _number");
	is ( Data::SimplePath::_is_number ($_), $_, "$_ _is_number");
}

# invalid values [10 * 3 tests]:
foreach ('abc', '.*', '0xabc', sub {}, v1.0, qr/.*/, {}, [], -1, '+2') {
	is (Data::SimplePath::_number ($_), undef, "$_ no valid _number");
	warning_like
		{ is (Data::SimplePath::_is_number ($_), undef, "$_ not _is_number")}
		qr/Trying to access array element with non-numeric key .+/;
}
