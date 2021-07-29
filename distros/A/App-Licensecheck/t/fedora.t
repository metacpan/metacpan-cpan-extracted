use Test2::V0;

use lib 't/lib';
use Test2::Licensecheck;

my $ver = $Regexp::Pattern::License::VERSION;

plan 36;

# TODO: simplify when Regexp::Pattern::License v3.7.0 is required
license_like(
	't/fedora/MIT',
	[   qr/Adobe\-Glyph/,
		qr/BSL/,
		qr/DSDP/,
		qr/Expat/,
		qr/ICU/,
		qr/MIT~Boehm/,
		qr/MIT\-CMU/,
		qr/MIT\-CMU~warranty/,
		qr/MIT\-enna/,
		qr/MIT\-feh/,
		qr/MIT~old/,
		qr/MIT~oldstyle/,
		qr/MIT~oldstyle~disclaimer/,
		qr/PostgreSQL/,
	]
);
my $todo = todo 'not implemented yet'
	if $ver < v3.7;
license_like(
	't/fedora/MIT',
	[   qr/Adobe\-Glyph/,
		qr/BSL/,
		qr/DSDP/,
		qr/Expat/,
		qr/ICU/,
		qr/MIT~Boehm/,
		qr/MIT\-CMU/,
		qr/MIT\-CMU~warranty/,
		qr/MIT\-enna/,
		qr/MIT~Epinions/,
		qr/MIT\-feh/,
		qr/MIT~old/,
		qr/MIT~oldstyle/,
		qr/MIT~oldstyle~disclaimer/,
		qr/MIT-Open-Group/,
		qr/MIT~OpenVision/,
		qr/MIT~OSF/,
		qr/MIT~UnixCrypt/,
		qr/MIT~whatever/,
		qr/MIT~Widget/,
		qr/MIT~Xfig/,
		qr/PostgreSQL/,
	]
);

done_testing;
