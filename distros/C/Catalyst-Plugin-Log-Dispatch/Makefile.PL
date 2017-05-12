use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Catalyst::Plugin::Log::Dispatch',
    AUTHOR        => 'Shota Takayama <shot[at]bindstorm.jp>',
    VERSION_FROM  => 'lib/Catalyst/Plugin/Log/Dispatch.pm',
    ABSTRACT_FROM => 'lib/Catalyst/Plugin/Log/Dispatch.pm',
    PREREQ_PM     => {
        'Test::More'            => 0,
        'Log::Dispatch'         => '2.13',
        'Catalyst'              => '5.65',
        'UNIVERSAL::require'    => 0,
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Catalyst-Plugin-Log-Dispatch-*' },
);
