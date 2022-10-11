#! perl -w
use strict;
use v5.10.1;

use ExtUtils::MakeMaker 6.55_02;

WriteMakefile(
    VERSION_FROM  => 'lib/Dancer2/Plugin/RPC/RESTISH.pm',
    ABSTRACT_FROM => 'lib/Dancer2/Plugin/RPC/RESTISH.pm',
    NAME          => 'Dancer2::Plugin::RPC::RESTISH',
    AUTHOR        => 'Abe Timmerman <abeltje@cpan.org>',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.55_02,
    },
    BUILD_REQUIRES => {
        'Test::Simple'   => 0.88,
        'Test::Fatal'    => 0,
        'Test::Warnings' => 0,
    },
    PREREQ_PM => {
        'Dancer2::Plugin::RPC' => '2.01_02',
    },

    MIN_PERL_VERSION => '5.010001',

    META_MERGE => {
        'meta-spec' => {
            version    => 2,
        },
        'resources' => {
            license    => [ 'perl_5'],
            homepage   => "https://github.com/abeltje/Dancer2-Plugin-RPC-RESTISH",
            repository => {
                type   => "git",
                url    => "git://github.com:abeltje/Dancer2-Plugin-RPC-RESTISH.git",
                web    => "https://github.com/abeltje/Dancer2-Plugin-RPC-RESTISH.git",
            },
#            x_IRC      => "irc://irc.perl.org/#amsterdam.pm",
        },
    },
);
