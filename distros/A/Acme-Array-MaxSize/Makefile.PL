use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Acme::Array::MaxSize',
    AUTHOR           => q{E. Choroba <choroba@cpan.org>},
    VERSION_FROM     => 'lib/Acme/Array/MaxSize.pm',
    ABSTRACT_FROM    => 'lib/Acme/Array/MaxSize.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        parent              => undef,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Acme-Array-MaxSize-*' },
);
