use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::SimpleScan::Plugin::Plaintext',
    AUTHOR              => 'Joe McMahon <mcmahon@yahoo-inc.com>',
    VERSION_FROM        => 'lib/App/SimpleScan/Plugin/Plaintext.pm',
    ABSTRACT_FROM       => 'lib/App/SimpleScan/Plugin/Plaintext.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'App::SimpleScan'    => 1.0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-SimpleScan-Plugin-Plaintext-*' },
);
