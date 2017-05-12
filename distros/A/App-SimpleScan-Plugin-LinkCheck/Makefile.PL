use strict;
use 5.008;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::SimpleScan::Plugin::LinkCheck',
    AUTHOR              => 'Joe McMahon <mcmahon@yahoo-inc.com>',
    VERSION_FROM        => 'lib/App/SimpleScan/Plugin/LinkCheck.pm',
    ABSTRACT_FROM       => 'lib/App/SimpleScan/Plugin/LinkCheck.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'App::SimpleScan' => 1.00,
        'Scalar::Util' => 0,
        'Text::Balanced' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-SimpleScan-Plugin-LinkCheck-*' },
);
