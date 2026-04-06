#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(ok done_testing);
use Test2::Tools::Compare qw(is like);
use File::Path qw(make_path);
use File::Spec ();
use File::Temp qw(tempdir);

# Explicit lib/ so this file passes under any harness (prove -l is not always applied).
use FindBin ();
use lib File::Spec->catdir( $FindBin::Bin, '..', 'lib' );

use App::prepare4release::Deps;

# --- scan: picks non-core module from lib -----------------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	make_path( File::Spec->catfile( $tmp, 'lib' ) );
	open my $pm, '>:encoding(UTF-8)', File::Spec->catfile( $tmp, 'lib', 'Z.pm' )
		or die $!;
	print {$pm} <<'PM';
package Z;
use strict;
use warnings;
use HTTP::Tiny;
our $VERSION = 1;
1;
PM
	close $pm;

	my ( $r, $t ) = App::prepare4release::Deps->scan_distribution(
		$tmp,
		{ module_name => 'Z' },
		0,
		'5.010000'
	);
	ok( exists $r->{'HTTP::Tiny'}, 'HTTP::Tiny seen in lib' );
	is( scalar keys %$t, 0, 'no test deps without t/' );
}

# --- sync writes Makefile.PL + cpanfile -------------------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	open my $j, '>:encoding(UTF-8)', File::Spec->catfile( $tmp, 'prepare4release.json' );
	print {$j} qq({"dependencies":{"sync":true}}\n);
	close $j;

	open my $mf, '>:encoding(UTF-8)', File::Spec->catfile( $tmp, 'Makefile.PL' );
	print {$mf} <<'MK';
use 5.010;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'Z::Dist',
    VERSION_FROM => 'lib/Z/Dist.pm',
    LICENSE => 'perl',
    MIN_PERL_VERSION => '5.010001',
    PREREQ_PM => {},
    TEST_REQUIRES => {},
);
MK
	close $mf;

	make_path( File::Spec->catfile( $tmp, 'lib', 'Z' ) );
	open my $pm, '>:encoding(UTF-8)', File::Spec->catfile( $tmp, 'lib', 'Z', 'Dist.pm' );
	print {$pm} <<'PM';
package Z::Dist;
use strict;
use JSON::PP;
our $VERSION = '0.01';
1;
PM
	close $pm;

	make_path( File::Spec->catfile( $tmp, 't' ) );
	open my $tt, '>:encoding(UTF-8)', File::Spec->catfile( $tmp, 't', 'x.t' );
	print {$tt} "use Test2::V1; ok 1; done_testing;\n";
	close $tt;

	open my $cf, '>:encoding(UTF-8)', File::Spec->catfile( $tmp, 'cpanfile' );
	print {$cf} "# mini\n";
	close $cf;

	open my $mfh, '<:encoding(UTF-8)', File::Spec->catfile( $tmp, 'Makefile.PL' );
	local $/;
	my $mfc = <$mfh>;
	close $mfh;

	my ( $new, $changed ) = App::prepare4release::Deps->apply(
		$tmp,
		File::Spec->catfile( $tmp, 'Makefile.PL' ),
		$mfc,
		{ module_name => 'Z::Dist', version_from_path => File::Spec->catfile( $tmp, 'lib', 'Z', 'Dist.pm' ) },
		{ dependencies => { sync => 1, sync_cpanfile => 1 } },
		{ sync_deps => 1, verbose => 0 }
	);

	ok( $changed, 'apply reported changes' );
	like( $new, qr/JSON::PP/, 'Makefile.PL lists JSON::PP' );
	like( $new, qr/Test2::V1/, 'Makefile.PL lists Test2::V1 in TEST_REQUIRES' );

	open my $c2, '<:encoding(UTF-8)', File::Spec->catfile( $tmp, 'cpanfile' );
	my $cft = <$c2>;
	close $c2;
	like( $cft, qr/requires 'JSON::PP'/, 'cpanfile got requires JSON::PP' );
	like( $cft, qr/test_requires 'Test2::V1'/, 'cpanfile got test_requires Test2::V1' );
}

done_testing;
