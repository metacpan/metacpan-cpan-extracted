use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.9.0';
use Test2::Require::Module 'Software::LicenseUtils'   => '0.103014';

use Test::Command::Simple;

use Software::LicenseUtils;
use Path::Tiny 0.053;

my @CMD
	= ( $ENV{'LICENSECHECK'} )
	|| path('blib')->exists
	? ('blib/script/licensecheck')
	: ( $^X, 'bin/licensecheck' );
diag "executable: @CMD";

my %LICENSES = (
	'AGPL-3.0'     => 'AGPL-3',
	'Apache-1.1'   => 'Apache-1.1',
	'Apache-2.0'   => 'Apache-2.0',
	'Artistic-1.0' => 'Artistic-1.0',
	'Artistic-2.0' => 'Artistic-2.0',
	BSD            => 'BSD-3-clause',
	'CC0-1.0'      => 'CC0-1.0',

#	Custom                                  => 'UNKNOWN',
	'EUPL-1.1'             => 'EUPL-1.1',
	'EUPL-1.2'             => 'EUPL-1.2',
	'BSD-2-Clause-FreeBSD' => 'BSD-2-clause',
	'GFDL-1.2-or-later'    => 'GFDL-1.2+',
	'GFDL-1.3-or-later'    => 'GFDL-1.3+',
	'GPL-1.0-only'         => 'GPL-1',
	'GPL-2.0-only'         => 'GPL-2',
	'GPL-3.0-only'         => 'GPL-3',

#	'LGPL-2.0'                              => 'LGPL-2',
	'LGPL-2.1' => 'LGPL-2.1',
	'LGPL-3.0' => 'LGPL-3',
	MIT        => 'Expat',
	'MPL-1.0'  => 'MPL-1.0',
	'MPL-1.1'  => 'MPL-1.1',
	'MPL-2.0'  => 'MPL-2.0',

#	None                                    => 'UNKNOWN',
	OpenSSL                                 => 'OpenSSL',
	'Artistic-1.0-Perl OR GPL-1.0-or-later' => 'GPL-1 and/or Perl',
	PostgreSQL                              => 'PostgreSQL',
	'QPL-1.0'                               => 'QPL-1.0',
	SSLeay                                  => 'SSLeay',
	SISSL                                   => 'SISSL',
	Zlib                                    => 'Zlib',
);

my $workdir = Path::Tiny->tempdir( CLEANUP => ( not $ENV{PRESERVE} ) );
diag("Detect PRESERVE in environment, so will keep workdir: $workdir")
	if $ENV{PRESERVE};
foreach ( keys %LICENSES ) {
	my $license;
	eval {
		$license = Software::LicenseUtils->new_from_spdx_expression(
			{   spdx_expression => $_,
				holder => 'Testophilus Testownik <tester@testity.org>',
				year   => 2000,
			}
		);
	};
	skip_all "Software::License failed to create license $_" if $@;
	$workdir->child($_)->spew_utf8( $license->notice, $license->license );
}
plan 4 + keys %LICENSES;

run_ok @CMD, qw(--recursive -m --deb-fmt -c .+), $workdir;
is stderr, '', 'No stderr';
foreach ( split /\v+/, stdout ) {
	if (m{^$workdir/([\S ]+)\t(.+)$}) {
		my $file    = $1;
		my $result  = $2;
		my $success = is $result, $LICENSES{$file}, $file;
		if ((      $LICENSES{$file} eq 'UNKNOWN'
				or $LICENSES{$file} eq
				'Apache-1.0 and/or BSD-4-clause and/or OpenSSL'
				or ( $file eq 'SSLeay' and $LICENSES{$file} ne 'SSLeay' )
			)
			and $success
			)
		{
			note "licensecheck failed to parse $file as expected";
		}
	}
	else {
		diag "Unexpected output: $_";
	}
}

done_testing;
