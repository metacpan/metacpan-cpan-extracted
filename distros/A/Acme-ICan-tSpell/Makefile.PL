use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Acme::ICan::tSpell',
    AUTHOR           => q{Robert Acock <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/Acme/ICan/tSpell.pm',
    ABSTRACT_FROM    => 'lib/Acme/ICan/tSpell.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::MockObject' => '1.20150527',
    },
    PREREQ_PM => {
        'Moo' => '2.003001',
        'MooX::LazierAttributes' => '1.07',
        'MooX::ValidateSubs' => '1.012003',
        'Type::Tiny' => '1.004002',
        'HTTP::Tiny' => '0.054', 
        'URI' => '1.71',
        'Carp' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Acme-ICan-tSpell-*' },
);
