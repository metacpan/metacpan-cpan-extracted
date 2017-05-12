use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Brocade::BSC',
    AUTHOR           => q{lwp <pruiklw@cpan.org>},
    VERSION_FROM     => 'lib/Brocade/BSC.pm',
    ABSTRACT_FROM    => 'lib/Brocade/BSC.pm',
    LICENSE          => 'BSD',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'version'             => 0.77,
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'strict'         => 0,
        'warnings'       => 0,
        'Carp'           => 0,
        'Carp::Assert'   => 0.21,
        'Clone'          => 0,
        'Data::Walk'     => 1.00,
        'Exporter'       => 0,
        'HTTP::Status'   => 0,
        'JSON'           => 2.90,
        'LWP'            => 6.08,
        'Readonly'       => 2.00,
        'Regexp::Common' => 2013031301,
        'URI::Escape'    => 0,
        'XML::Parser'    => 2.44,
        'YAML'           => 1.15,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Brocade-BSC-*' },
);
