use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'ArangoDB2',
    AUTHOR           => q{Ersun Warncke <ersun.warncke@outlook.com>},
    VERSION_FROM     => 'lib/ArangoDB2.pm',
    ABSTRACT_FROM    => 'lib/ArangoDB2.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Data::Dumper'      => 0,
        'LWP::UserAgent'    => 0,
        'JSON::XS'          => 0,
        'Scalar::Util'      => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'ArangoDB2-*' },
);
