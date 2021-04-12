use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Config::LNPath',
    AUTHOR           => q{Robert Acock <email@lnation.org>},
    VERSION_FROM     => 'lib/Config/LNPath.pm',
    ABSTRACT_FROM    => 'lib/Config/LNPath.pm',
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
        'YAML::XS' => '0.66',
        'Data::LNPath' => '1.00',
	'Carp' => '0',
	'Blessed::Merge' => '0.07'
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Config-LNPath-*' },
);
