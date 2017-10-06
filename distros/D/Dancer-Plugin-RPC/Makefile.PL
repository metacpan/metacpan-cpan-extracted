#! perl -w
use strict;
use v5.10.1;

use ExtUtils::MakeMaker '6.55_02';

WriteMakefile(
    NAME          => 'Dancer::Plugin::RPC',
    VERSION_FROM  => 'lib/Dancer/Plugin/RPC.pm',
    ABSTRACT_FROM => 'lib/Dancer/Plugin/RPC.pm',
    AUTHOR        => 'Abe Timmerman <abeltje@cpan.org>',
    LICENSE       => 'perl',

    PREREQ_PM => {
        'Dancer'                     => '1.31',
        'JSON'                       => '2.0',
        'Params::ValidationCompiler' => '0.24',
        'RPC::XML'                   => '0.56',
        'Types::Standard'            => '1.00',
    },

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.55_02',
    },

    BUILD_REQUIRES => {
        'Test::Fatal'      => '0.010',
        'Test::More'       => '0.88',    # done_testing()
        'Test::NoWarnings' => '1.00',
    },

    MIN_PERL_VERSION => '5.010001',

    META_ADD => {
        'meta-spec' => {
            version    => 2,
        },
        'resources' => {
            homepage   => "https://github.com/abeltje/Dancer-Plugin-RPC",
            repository => {
                type   => "git",
                url    => "git://github.com/abeltje/Dancer-Plugin-RPC.git",
                web    => "https://github.com/abeltje/Dancer-Plugin-RPC",
            },
#            x_IRC      => "irc://irc.perl.org/#amsterdam.pm",
        },
    },
);
