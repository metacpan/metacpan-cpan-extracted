use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::Plugin::ClamAV',
    AUTHOR              => 'FUJIWARA Shunichiro <fujiwara@topicmaker.com>',
    VERSION_FROM        => 'lib/Catalyst/Plugin/ClamAV.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/Plugin/ClamAV.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Catalyst'       => 0,
        'Test::More'     => 0,
        'ClamAV::Client' => 0.10,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-Plugin-ClamAV-*' },
);
