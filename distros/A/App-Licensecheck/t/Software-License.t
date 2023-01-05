use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.9.0';
use Test2::Require::Module 'Software::LicenseUtils'   => '0.103014';

use App::Licensecheck;
use Software::LicenseUtils;
use Path::Tiny 0.053;

plan 28;

my @opts = (
	schemes   => [qw(spdx)],
	top_lines => 0,
);

my %LICENSES = (
	'AGPL-3.0'             => 'AGPLv3',
	'Apache-1.1'           => '',
	'Apache-2.0'           => '',
	'Artistic-1.0'         => '',
	'Artistic-2.0'         => '',
	'BSD'                  => 'BSD-3-Clause',
	'CC0-1.0'              => '',
	'EUPL-1.1'             => '',
	'EUPL-1.2'             => '',
	'BSD-2-Clause-FreeBSD' => 'BSD-2-Clause',
	'GFDL-1.2-or-later'    => 'GFDL-1.2-or-later and/or GFDL-1.3',
	'GFDL-1.3-or-later'    => '',
	'GPL-1.0-only'         => 'GPL-1.0',
	'GPL-2.0-only'         => 'GPL-2',
	'GPL-3.0-only'         => 'GPL-3',
	'LGPL-2.1'             => '',
	'LGPL-3.0'             => 'LGPL-3',
	'MIT'                  => '',
	'MPL-1.0'              => '',
	'MPL-1.1'              => '',
	'MPL-2.0'              => '',
	'OpenSSL'              => 'OpenSSL and/or SSLeay',
	'Artistic-1.0-Perl OR GPL-1.0-or-later' =>
		'Artistic-1.0 and/or GPL-1.0 and/or Perl',
	'PostgreSQL' => '',
	'QPL-1.0'    => '',
	'SSLeay'     => '',
	'SISSL'      => '',
	'Zlib'       => '',
);

my $workdir = Path::Tiny->tempdir( CLEANUP => ( not $ENV{PRESERVE} ) );
diag("Detect PRESERVE in environment, so will keep workdir: $workdir")
	if $ENV{PRESERVE};
foreach my $id ( sort keys %LICENSES ) {
	my ( $license, $file, $expected, $resolved );
	eval {
		$license = Software::LicenseUtils->new_from_spdx_expression(
			{   spdx_expression => $id,
				holder => 'Testophilus Testownik <tester@testity.org>',
				year   => 2000,
			}
		);
	};
	skip_all "Software::License failed to create license $id" if $@;
	$file = $workdir->child($id);
	$file->spew_utf8( $license->notice, $license->license );
	$expected = $LICENSES{$id} || $id;
	($resolved) = App::Licensecheck->new(@opts)->parse($file);
	like $resolved, $expected,
		"matches expected license for SPDX id $id";
}

done_testing;
