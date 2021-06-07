use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Data::Validate::Perl',
    AUTHOR           => q{Dongxu Ma <dongxu@cpan.org>},
    VERSION_FROM     => 'lib/Data/Validate/Perl.pm',
    ABSTRACT_FROM    => 'lib/Data/Validate/Perl.pm',
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
        'Parse::Yapp' => 1.05,
    },
    EXE_FILES => [
        'bin/dvp_gen_parser',
    ],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-Validate-Perl-*' },
);
