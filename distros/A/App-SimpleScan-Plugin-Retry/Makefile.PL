use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::SimpleScan::Plugin::Retry',
    AUTHOR              => 'Joe McMahon <mcmahon@yahoo-inc.com >',
    VERSION_FROM        => 'lib/App/SimpleScan/Plugin/Retry.pm',
    ABSTRACT_FROM       => 'lib/App/SimpleScan/Plugin/Retry.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'App::SimpleScan'    => 1.00,
        'WWW::Mechanize::Plugin::Retry' => 0.02,
        'Scalar::Util' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-SimpleScan-Plugin-Retry-*' },
);
