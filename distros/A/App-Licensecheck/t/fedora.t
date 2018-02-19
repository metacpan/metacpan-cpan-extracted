#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::Licensecheck tests => 2;

is_licensed(
	't/fedora/MIT',
	[   'Adobe-Glyph and/or BSL and/or DSDP and/or Expat and/or ICU and/or MIT-CMU and/or MIT-CMU~warranty and/or MIT-enna and/or MIT-feh and/or MIT~old and/or MIT~oldstyle and/or MIT~oldstyle~disclaimer and/or PostgreSQL and/or bdwgc',
		'an even longer list...'
	]
);

done_testing;
