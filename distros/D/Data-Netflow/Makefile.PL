use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Data::Netflow',
    AUTHOR           => q{DULAUNOY Fabrice <fabrice@dulaunoy.com>},
    VERSION_FROM     => 'lib/Data/Netflow.pm',
    ABSTRACT_FROM    => 'lib/Data/Netflow.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
          'List::Util'     => '1.48',
          'Socket'         => '2.020_03',
          'Time::HiRes'    => '1.9741'
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-Netflow-*' },
);
