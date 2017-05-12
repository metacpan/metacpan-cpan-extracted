use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'CHI::Driver::DBIC',
    AUTHOR           => q{Motortrak Ltd <duncan.garland@motortrak.com>},
    VERSION_FROM     => 'lib/CHI/Driver/DBIC.pm',
    ABSTRACT_FROM    => 'lib/CHI/Driver/DBIC.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
	'Params::Validate' => '0',
	'CHI' => '0',
	'CHI::Driver' => '0',
	'Moose' => '0',
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'CHI-Driver-DBIC-*' },
);
