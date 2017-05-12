use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::SimpleScan::Plugin::Forget',
    AUTHOR              => 'Joe McMahon <mcmahon@yahoo-inc.com >',
    VERSION_FROM        => 'lib/App/SimpleScan/Plugin/Forget.pm',
    ABSTRACT_FROM       => 'lib/App/SimpleScan/Plugin/Forget.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Differences' => 0,
        'App::SimpleScan'    => 1.00,
    
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-SimpleScan-Plugin-Forget-*' },
);
