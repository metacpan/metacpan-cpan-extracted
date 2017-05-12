use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::PGMultiDeploy',
    AUTHOR           => q{Chris Travers <chris@efficito.com>},
    VERSION_FROM     => 'lib/App/PGMultiDeploy.pm',
    ABSTRACT_FROM    => 'lib/App/PGMultiDeploy.pm',
    LICENSE          => 'bsd',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'PGObject::Util::DBChange' => 0,
        'Config::IniFiles' => 0,
        'Moo' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-PGMultiDeploy-*' },
);
