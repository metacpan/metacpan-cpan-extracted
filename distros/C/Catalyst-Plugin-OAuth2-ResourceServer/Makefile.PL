use v5.36;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Catalyst::Plugin::OAuth2::ResourceServer',
    VERSION_FROM     => 'lib/Catalyst/Plugin/OAuth2/ResourceServer.pm',
    ABSTRACT         => 'MCP-profile OAuth 2.1 Resource Server plugin for Catalyst',
    AUTHOR           => 'Mike Whitaker <mike@altrion.org>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.036',
    PREREQ_PM => {
        'Moo'                    => 0,
        'MooX::StrictConstructor' => 0,
        'namespace::clean'       => 0,
        'Carp'                   => 0,
        'Scalar::Util'           => 0,
        'Try::Tiny'              => 0,
        'Crypt::JWT'             => 0,
        'JSON::MaybeXS'          => 0,
        'URI'                    => 0,
        'Catalyst::Runtime'      => '5.90000',
    },
    TEST_REQUIRES => {
        'Test::More'            => '0.98',
        'Test::Fatal'           => 0,
        'HTTP::Request::Common' => 0,
        'Moose'                 => 0,
        'namespace::autoclean'  => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/fleetfootmike/Catalyst-Plugin-OAuth2-ResourceServer.git',
                web  => 'https://github.com/fleetfootmike/Catalyst-Plugin-OAuth2-ResourceServer',
            },
            bugtracker => {
                web => 'https://github.com/fleetfootmike/Catalyst-Plugin-OAuth2-ResourceServer/issues',
            },
            homepage => 'https://github.com/fleetfootmike/Catalyst-Plugin-OAuth2-ResourceServer',
        },
    },
    clean => { FILES => 'Catalyst-Plugin-OAuth2-ResourceServer-*' },
);
