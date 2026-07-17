use v5.36;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Catalyst::Plugin::OAuth2::AuthorizationServer',
    VERSION_FROM     => 'lib/Catalyst/Plugin/OAuth2/AuthorizationServer.pm',
    ABSTRACT         => 'MCP-profile OAuth 2.1 Authorization Server plugin for Catalyst',
    AUTHOR           => 'Mike Whitaker <mike@altrion.org>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.036',
    PREREQ_PM => {
        'Moo'                  => 0,
        'MooX::StrictConstructor' => 0,
        'Moo::Role'            => 0,
        'namespace::clean'     => 0,
        'Scalar::Util'         => 0,
        'Crypt::JWT'           => 0,
        'Bytes::Random::Secure' => 0,
        'Digest::SHA'          => 0,
        'MIME::Base64'         => '3.11',   # encode_base64url
        'JSON::MaybeXS'        => 0,
        'Try::Tiny'            => 0,
        'URI'                  => 0,
        'Catalyst::Runtime'    => '5.90000',
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
                url  => 'https://github.com/fleetfootmike/Catalyst-Plugin-OAuth2-AuthorizationServer.git',
                web  => 'https://github.com/fleetfootmike/Catalyst-Plugin-OAuth2-AuthorizationServer',
            },
            bugtracker => {
                web => 'https://github.com/fleetfootmike/Catalyst-Plugin-OAuth2-AuthorizationServer/issues',
            },
            homepage => 'https://github.com/fleetfootmike/Catalyst-Plugin-OAuth2-AuthorizationServer',
        },
    },
    clean => { FILES => 'Catalyst-Plugin-OAuth2-AuthorizationServer-*' },
);
