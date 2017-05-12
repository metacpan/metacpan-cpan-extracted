use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Bundle::Padre::Plugin',
    AUTHOR           => q{Albert Croft <atcroft@cpan.org>},
    VERSION_FROM     => 'lib/Bundle/Padre/Plugin.pm',
    ABSTRACT_FROM    => 'lib/Bundle/Padre/Plugin.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Padre'             => 0.90,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Bundle-Padre-Plugin-*' },
);
