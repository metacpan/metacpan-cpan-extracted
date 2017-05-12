use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Lvalue',
    AUTHOR              => q{Lukas Mai <l.mai@web.de>},
    VERSION_FROM        => 'lib/Acme/Lvalue.pm',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.56',
    },
    LICENSE => 'perl',
    PL_FILES            => {},
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Config' => 0,
    },
    PREREQ_PM => {
        'warnings' => 0,
        'strict' => 0,
        'Carp' => 0,
        'Math::Trig' => 0,
    },
    MIN_PERL_VERSION => '5.16.0',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                url => 'git://github.com/mauke/Acme-Lvalue.git',
                web => 'https://github.com/mauke/Acme-Lvalue',
                type => 'git',
            },
        },
    },
    depend => { Makefile => '$(VERSION_FROM)' },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Lvalue-*' },
);
