use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::SimpleScan::Plugin::Snapshot',
    AUTHOR              => 'Joe McMahon <mcmahon@yahoo-inc.com >',
    VERSION_FROM        => 'lib/App/SimpleScan/Plugin/Snapshot.pm',
    ABSTRACT_FROM       => 'lib/App/SimpleScan/Plugin/Snapshot.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'App::SimpleScan'    => 1.00,
        'WWW::Mechanize::Plugin::Snapshot'    => 0.12,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-SimpleScan-Plugin-Snapshot-*' },
);
