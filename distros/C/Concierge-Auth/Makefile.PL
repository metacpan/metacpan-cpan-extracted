use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Concierge::Auth',
    VERSION_FROM     => 'lib/Concierge/Auth.pm',
    AUTHOR           => 'Bruce Van Allen <bva@cruzio.com>',
    ABSTRACT         => 'Password authentication and token generation using Crypt::Passphrase',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.036',
    PREREQ_PM => {
        'Carp'             => 0,
        'Fcntl'            => 0,
        'Crypt::Passphrase'          => 0,
        'Crypt::Passphrase::Argon2'  => 0,
        'Crypt::Passphrase::Bcrypt'  => 0,
        'Crypt::PRNG'      => 0,
        'Time::HiRes'      => 0,
        'parent'           => 0,
        'Exporter'         => 0,
    },

    TEST_REQUIRES => {
        'Test2::V0' => 0,
    },

    EXE_FILES => [],

    PM => {
        'lib/Concierge/Auth.pm'              => '$(INST_LIB)/Concierge/Auth.pm',
        'lib/Concierge/Auth/Base.pm'          => '$(INST_LIB)/Concierge/Auth/Base.pm',
        'lib/Concierge/Auth/Generators.pm'   => '$(INST_LIB)/Concierge/Auth/Generators.pm',
        'lib/Concierge/Auth/Pwd.pm'           => '$(INST_LIB)/Concierge/Auth/Pwd.pm',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/bwva/Concierge-Auth.git',
                web  => 'https://github.com/bwva/Concierge-Auth',
            },
            bugtracker => {
                web => 'https://github.com/bwva/Concierge-Auth/issues',
            },
        },
        provides => {
            'Concierge::Auth' => {
                file    => 'lib/Concierge/Auth.pm',
                version => 'v0.5.1',
            },
            'Concierge::Auth::Base' => {
                file    => 'lib/Concierge/Auth/Base.pm',
                version => 'v0.5.1',
            },
            'Concierge::Auth::Generators' => {
                file    => 'lib/Concierge/Auth/Generators.pm',
                version => 'v0.4.5',
            },
            'Concierge::Auth::Pwd' => {
                file    => 'lib/Concierge/Auth/Pwd.pm',
                version => 'v0.5.1',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Concierge-Auth-*' },
);

sub MY::postamble {
    return <<'MAKE_FRAG';
cover :
	cover -test
MAKE_FRAG
}