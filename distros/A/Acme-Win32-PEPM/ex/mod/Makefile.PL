use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use Win32::PEPM::Build;

my %hash = (
    NAME             => 'Win32::PEPM::Test',
    AUTHOR           => q{Daniel Dragan <bulkdd@cpan.org>},
    VERSION_FROM     => 'lib/Win32/PEPM/Test.pm',
    ABSTRACT_FROM    => 'lib/Win32/PEPM/Test.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Win32::PEPM' => 0, #duh
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Win32-PEPM-Test-* *.ilk' },
);

Win32::PEPM::Build::WMHash(\%hash); #rewrite %hash as needed
WriteMakefile(%hash);
