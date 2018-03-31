use strictures 2;

use Test::Requires { 'Software::License' => '0.103008' };
use Software::LicenseUtils;
use Path::Tiny;

use Test::More;
use Test::Script;

my %LICENSES = (
	AGPL_3       => 'AGPL-3',
	Apache_1_1   => 'Apache-1.1',
	Apache_2_0   => 'Apache-2.0',
	Artistic_1_0 => 'Artistic-1.0',
	Artistic_2_0 => 'Artistic-2.0',
	BSD          => 'BSD-3-clause',
	CC0_1_0      => 'UNKNOWN',
	FreeBSD      => 'BSD-2-clause',
	GFDL_1_2     => 'GFDL-1.2+',
	GFDL_1_3     => 'GFDL-1.3+',
	GPL_1        => 'GPL-1',
	GPL_2        => 'GPL-2',
	GPL_3        => 'GPL-3',
	LGPL_2_1     => 'LGPL-2.1',
	LGPL_2       => 'LGPL-2',
	LGPL_3_0     => 'LGPL-3',
	MIT          => 'Expat',
	Mozilla_1_0  => 'MPL-1.0',
	Mozilla_1_1  => 'MPL-1.1',
	Mozilla_2_0  => 'MPL-2.0',
	None         => 'UNKNOWN',
	OpenSSL      => 'OpenSSL',
	Perl_5       => 'Artistic or GPL-1+',
	PostgreSQL   => 'PostgreSQL',
	QPL_1_0      => 'QPL-1.0',
	SSLeay       => 'BSD-2-clause',
	Sun          => 'UNKNOWN',
	Zlib         => 'Zlib',
);

my $workdir = Path::Tiny->tempdir( CLEANUP => ( not $ENV{PRESERVE} ) );
diag("Detect PRESERVE in environment, so will keep workdir: $workdir")
	if $ENV{PRESERVE};
foreach ( keys %LICENSES ) {
	my $license;
	eval {
		$license = Software::LicenseUtils->new_from_short_name(
			{   short_name => $_,
				holder     => 'Testophilus Testownik <tester@testity.org>',
				year       => 2000,
			}
		);
	};
	plan skip_all => "Software::License failed to create license $_" if $@;
	$workdir->child($_)->spew( $license->notice, $license->license );
}
plan tests => scalar( 1 + keys %LICENSES );
my $corpus = $workdir;
script_runs(
	[ 'bin/licensecheck', qw(--recursive -m --deb-fmt -c .+), "$corpus" ],
	{ stdout => \my $stdout },
);
foreach ( split /\v+/, $stdout ) {
	if (m{^$workdir/(\w+)\t(.+)$}) {
		my $file    = $1;
		my $result  = $2;
		my $success = is( $result, $LICENSES{$file}, $file );
		if ( $LICENSES{$file} eq 'UNKNOWN' and $success ) {
			diag("licensecheck failed to parse $file as expected");
		}
	}
	else {
		die "Unexpected output: $_";
	}
}
