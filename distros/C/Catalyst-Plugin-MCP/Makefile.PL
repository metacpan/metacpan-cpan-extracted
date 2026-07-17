use v5.36;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Catalyst::Plugin::MCP',
    VERSION_FROM     => 'lib/Catalyst/Plugin/MCP.pm',
    ABSTRACT         => 'Model Context Protocol server plugin for Catalyst',
    AUTHOR           => 'Mike Whitaker <mike@altrion.org>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.036',
    PREREQ_PM => {
        'Moo'                              => 0,
        'Moo::Role'                        => 0,
        'namespace::clean'                 => 0,
        'Scalar::Util'                     => 0,
        'Catalyst::Plugin::JSONRPC::Server' => '0.003',
        'Catalyst::Runtime'                => '5.90000',
    },
    TEST_REQUIRES => {
        'Test::More'            => '0.98',
        'Test::Fatal'           => 0,
        'HTTP::Request::Common' => 0,
        'JSON::MaybeXS'         => 0,
        'Moose'                 => 0,
        'namespace::autoclean'  => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/fleetfootmike/Catalyst-Plugin-MCP.git',
                web  => 'https://github.com/fleetfootmike/Catalyst-Plugin-MCP',
            },
            bugtracker => {
                web => 'https://github.com/fleetfootmike/Catalyst-Plugin-MCP/issues',
            },
            homepage => 'https://github.com/fleetfootmike/Catalyst-Plugin-MCP',
        },
    },
    clean => { FILES => 'Catalyst-Plugin-MCP-*' },
);
