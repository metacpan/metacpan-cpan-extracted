#! perl -w
use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
    VERSION_FROM  => 'lib/Dancer/Plugin/RPC/RESTISH.pm',
    ABSTRACT_FROM => 'lib/Dancer/Plugin/RPC/RESTISH.pm',
    NAME          => 'Dancer::Plugin::RPC::RESTISH',
    AUTHOR        => 'Abe Timmerman <abeltje@cpan.org>',

    PREREQ_PM => {
        'Dancer::Plugin::RPC' => '1.07_02',
    },
);
