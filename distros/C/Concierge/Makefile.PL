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
        'Concierge::Auth'    => 0,
        'Concierge::Sessions' => 0,
        'Concierge::Users'   => 0,
    },

    TEST_REQUIRES => {
        'Test2::V0' => 0,
    },

    EXE_FILES => [],

    PM => {
        'lib/Concierge.pm'       => '$(INST_LIB)/Concierge.pm',
        'lib/Concierge/Base.pm'  => '$(INST_LIB)/Concierge/Base.pm',
        'lib/Concierge/Setup.pm' => '$(INST_LIB)/Concierge/Setup.pm',
        'lib/Concierge/User.pm'  => '$(INST_LIB)/Concierge/User.pm',
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
                version => 'v0.7.0',
            },
            'Concierge::Base' => {
                file    => 'lib/Concierge/Base.pm',
                version => 'v0.7.0',
            },
            'Concierge::Setup' => {
                file    => 'lib/Concierge/Setup.pm',
                version => 'v0.7.0',
            },
            'Concierge::User' => {
                file    => 'lib/Concierge/User.pm',
                version => 'v0.7.0',
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