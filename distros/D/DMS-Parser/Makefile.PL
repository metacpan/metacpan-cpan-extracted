use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'DMS-Parser',
    VERSION_FROM     => 'lib/DMS/Parser.pm',
    ABSTRACT         => 'Pure-Perl parser for DMS, a data syntax with strong typing, ordered maps, and heredocs',
    AUTHOR           => 'Filip Lopes',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.014',
    PREREQ_PM        => {
        'Tie::IxHash' => 0,
        'POSIX'       => 0,
        'Math::BigInt'=> 0,
        'Encode'      => 0,
    },
    TEST_REQUIRES    => {
        'Test::More'  => 0,
        'FindBin'     => 0,
    },
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://gitlab.com/flo-labs/pub/dms-pl.git',
                web  => 'https://gitlab.com/flo-labs/pub/dms-pl',
            },
        },
    },
);
