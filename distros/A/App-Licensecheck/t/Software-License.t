use strictures 2;

use Test::Requires { 'Software::License' => '0.103008' };
use Software::LicenseUtils;
use Path::Tiny;

use Test::More;
use Test::Script;

my %LICENSES = (
	Apache_2_0   => 'Apache (v2.0)',
	FreeBSD      => 'BSD (2 clause)',
	GPL_1        => 'GPL (v1)',
	GPL_2        => 'GPL (v2)',
	GPL_3        => 'GPL (v3)',
	LGPL_2       => 'LGPL (v2)',
	LGPL_2_1     => 'LGPL (v2.1)',
	LGPL_3_0     => 'LGPL (v3)',
	MIT          => 'MIT/X11 (BSD like)',
	Mozilla_2_0  => 'MPL (v2.0)',
	QPL_1_0      => 'QPL (v1.0)',
	Zlib         => 'zlib/libpng',
	CC0_1_0      => 'UNKNOWN',
	GFDL_1_3     => 'UNKNOWN',
	Artistic_1_0 => 'Artistic (v1.0)',
	Artistic_2_0 => 'Artistic (v2.0)',
	Mozilla_1_0  => 'MPL (v1.0)',
	None         => 'UNKNOWN',
	PostgreSQL   => 'PostgreSQL',
	AGPL_3       => 'AGPL (v3)',
	SSLeay       => 'BSD (2 clause)',
	Apache_1_1   => 'Apache (v1.1)',
	Mozilla_1_1  => 'MPL (v1.1)',
	GFDL_1_2     => 'UNKNOWN',
	Sun          => 'UNKNOWN',
	BSD          => 'BSD (3 clause)',
	OpenSSL      => 'UNKNOWN',
	Perl_5       => 'Perl',
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
	[ 'bin/licensecheck', qw(--recursive -m -c .+), "$corpus" ],
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
