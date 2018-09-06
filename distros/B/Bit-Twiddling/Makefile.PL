use strict;
use warnings;

use ExtUtils::MakeMaker 6.48;

WriteMakefile(
    NAME             => 'Bit::Twiddling',
    AUTHOR           => 'Brian Greenfield <briang@cpan.org>',
    VERSION_FROM     => 'lib/Bit/Twiddling.pm',
    ABSTRACT_FROM    => 'lib/Bit/Twiddling.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.008',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.48',
    },
    BUILD_REQUIRES => {
        # 'Inline::C' => '0'
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
        'Test::Warn' => '0',
        'Config'     => '0',
    },
    PREREQ_PM => {
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Bit-Twiddling-*' },
    META_MERGE         => {
        'meta-spec'    => { version => 2 },
        resources      => {
            bugtracker => {
                web    => 'https://github.com/briang/p5-bit-twiddling/issues'
            },
            homepage   => 'https://github.com/briang/p5-bit-twiddling',
            repository => {
                type   => 'git',
                url    => 'git://github.com/briang/p5-bit-twiddling.git',
                web    => 'https://github.com/briang/p5-bit-twiddling',
            },
        },
    },
);
