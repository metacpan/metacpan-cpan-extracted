use 5.008;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use Config;

if (WriteMakefile(
    NAME               => 'Common::CodingTools',
    AUTHOR             => q{Richard Kelsch <rich@rk-internet.com>},
    VERSION_FROM       => 'lib/Common/CodingTools.pm',
    ABSTRACT_FROM      => 'lib/Common/CodingTools.pm',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.008000,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'  => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0.44,
    },
    PREREQ_PM      => {
        'Exporter::Easy' => 0.16,
        'List::Util'     => 1.41,
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
    clean => {FILES    => 'Common-CodingTools-*'},
)) {
    exit(0);
}

exit(1);
