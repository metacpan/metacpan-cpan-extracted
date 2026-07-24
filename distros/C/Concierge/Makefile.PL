use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Concierge',
    VERSION_FROM     => 'lib/Concierge.pm',
    AUTHOR           => 'Bruce Van Allen <bva@cruzio.com>',
    ABSTRACT         => 'Service layer orchestrator for authentication, sessions, and user data',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.036',
    PREREQ_PM => {
        'Carp'               => 0,
        'JSON::PP'           => 0,
        'Params::Filter'     => '0.014',
        'Concierge::Auth'     => '0.5.2',
        'Concierge::Sessions' => '0.11.3',
        'Concierge::Users'    => '0.9.4',
    },

    TEST_REQUIRES => {
        'Test2::V0' => 0,
    },

    EXE_FILES => [],

    PM => {
        'lib/Concierge.pm'                           => '$(INST_LIB)/Concierge.pm',
        'lib/Concierge/Desk/Component.pm'            => '$(INST_LIB)/Concierge/Desk/Component.pm',
        'lib/Concierge/Desk/UnavailableComponent.pm' => '$(INST_LIB)/Concierge/Desk/UnavailableComponent.pm',
        'lib/Concierge/Desk/Setup.pm'                => '$(INST_LIB)/Concierge/Desk/Setup.pm',
        'lib/Concierge/Desk/User.pm'                 => '$(INST_LIB)/Concierge/Desk/User.pm',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/bwva/Concierge.git',
                web  => 'https://github.com/bwva/Concierge',
            },
            bugtracker => {
                web => 'https://github.com/bwva/Concierge/issues',
            },
        },
        provides => {
            'Concierge' => {
                file    => 'lib/Concierge.pm',
                version => 'v0.11.0',
            },
            'Concierge::Desk::Component' => {
                file    => 'lib/Concierge/Desk/Component.pm',
                version => 'v0.11.0',
            },
            'Concierge::Desk::UnavailableComponent' => {
                file    => 'lib/Concierge/Desk/UnavailableComponent.pm',
                version => 'v0.11.0',
            },
            'Concierge::Desk::Setup' => {
                file    => 'lib/Concierge/Desk/Setup.pm',
                version => 'v0.11.0',
            },
            'Concierge::Desk::User' => {
                file    => 'lib/Concierge/Desk/User.pm',
                version => 'v0.11.0',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Concierge-*' },
);

sub MY::postamble {
    return <<'MAKE_FRAG';
cover :
	cover -test
MAKE_FRAG
}