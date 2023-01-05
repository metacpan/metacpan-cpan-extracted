use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.7.0';

use App::Licensecheck;

plan 22;

my @opts = (
	schemes   => [qw(debian spdx)],
	top_lines => 0,
);

my ($license) = App::Licensecheck->new(@opts)->parse('t/fedora/MIT');
like $license, qr/Adobe\-Glyph/;
like $license, qr/BSL/;
like $license, qr/DSDP/;
like $license, qr/Expat/;
like $license, qr/ICU/;
like $license, qr/MIT~Boehm/;
like $license, qr/MIT\-CMU/;
like $license, qr/MIT\-CMU~warranty/;
like $license, qr/MIT\-enna/;
like $license, qr/MIT~Epinions/;
like $license, qr/MIT\-feh/;
like $license, qr/MIT~old/;
like $license, qr/MIT~oldstyle/;
like $license, qr/MIT~oldstyle~disclaimer/;
like $license, qr/MIT-Open-Group/;
like $license, qr/MIT~OpenVision/;
like $license, qr/MIT~OSF/;
like $license, qr/MIT~UnixCrypt/;
like $license, qr/MIT~whatever/;
like $license, qr/MIT~Widget/;
like $license, qr/MIT~Xfig/;
like $license, qr/PostgreSQL/;

done_testing;
