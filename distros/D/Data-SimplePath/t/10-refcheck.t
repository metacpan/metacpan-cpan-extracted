#!/usr/bin/perl -T

use strict;
use warnings;

use Data::SimplePath;

BEGIN {
	use Test::More;
	use Test::NoWarnings;
	plan ('tests' => 29);
}

# _arrayref must return true for arrayrefs, false for anything else:
ok (Data::SimplePath::_arrayref ([]), 'Is an arrayref');
foreach ('a', qr/.*/, sub {}, {}, \('a'), \([]), v1.0) {
	ok (not (Data::SimplePath::_arrayref ($_)), "Not an arrayref: $_");
}

# same for _hashref:
ok (Data::SimplePath::_hashref ({}), 'Is a hashref');
foreach ('a', qr/.*/, sub {}, [], \('a'), \({}), v1.0) {
	ok (not (Data::SimplePath::_hashref ($_)), "Not a hashref: $_");
}

# _valid_root must be (_hashref or _arrayref):
ok (Data::SimplePath::_valid_root ({}), 'Is an arrayref (root)');
ok (Data::SimplePath::_valid_root ([]), 'Is a hashref (root)');
foreach ('a', qr/.*/, sub {}, \('a'), \({}), \([]), v1.0) {
	ok (not (Data::SimplePath::_valid_root ($_)), "Not a root: $_");
}

# additionally, _valid_root can be an object method:
my $h = Data::SimplePath -> new ();
ok (not ($h -> _valid_root ()), 'Object without valid root');

$h = Data::SimplePath -> new ({});
ok ($h -> _valid_root (), 'Hashref root ok');

$h = Data::SimplePath -> new ([]);
ok ($h -> _valid_root (), 'Arrayref root ok');
