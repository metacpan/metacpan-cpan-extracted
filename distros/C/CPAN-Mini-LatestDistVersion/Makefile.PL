use inc::Module::Install 1.00;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/CPAN/Mini/LatestDistVersion.pm > README' );
}

perl_version '5.010';

name 'CPAN-Mini-LatestDistVersion';
all_from 'lib/CPAN/Mini/LatestDistVersion.pm';

requires 'CPAN::Mini';
requires 'CPAN::DistnameInfo';
requires 'Parse::CPAN::Packages::Fast';

test_requires 'Test::More' => '0.96';
extra_tests;

repository 'http://github.com/bricas/cpan-mini-latestdistversion';

WriteAll;
