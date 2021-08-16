use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.7.0';

use lib 't/lib';
use Test2::Licensecheck;

plan 22;

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
