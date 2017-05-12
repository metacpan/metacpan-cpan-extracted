use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::SimpleScan::Plugin::Cache',
    AUTHOR              => 'Joe McMahon <mcmahon@yahoo-inc.com >',
    VERSION_FROM        => 'lib/App/SimpleScan/Plugin/Cache.pm',
    ABSTRACT_FROM       => 'lib/App/SimpleScan/Plugin/Cache.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'App::SimpleScan'    => 0.16,
        'Module::Pluggable' => 0,
        'WWW::Mechanize::Pluggable' => 0.08,
        'WWW::Mechanize::Plugin::Cache' => 0.01,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-SimpleScan-Plugin-Cache-*' },
);
