#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::Licensecheck tests => 15;

license_like(
	't/fedora/MIT',
	[   qr/Adobe\-Glyph/,
		qr/BSL/, qr/DSDP/,
		qr/Expat/,
		qr/ICU/,
		qr/MIT\-CMU/,
		qr/MIT\-CMU~warranty/,
		qr/MIT\-enna/,
		qr/MIT\-feh/,
		qr/MIT~old/,
		qr/MIT~oldstyle/,
		qr/MIT~oldstyle~disclaimer/,
		qr/PostgreSQL/,
		qr/MIT~Boehm|bdwgc/,
	]
);
license_is(
	't/fedora/MIT',
	[   undef,
		'an even longer list...'
	]
);

done_testing;
