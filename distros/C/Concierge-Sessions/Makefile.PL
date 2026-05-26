use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Concierge::Sessions',
    VERSION_FROM     => 'lib/Concierge/Sessions.pm',
    AUTHOR           => 'Bruce Van Allen <bva@cruzio.com>',
    ABSTRACT         => 'Session management with multiple backend support',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.036',

    PREREQ_PM => {
        'Carp'           => 0,
        'Crypt::PRNG'    => 0,
        'DBI'            => 0,
        'DBD::SQLite'    => 0,
        'Time::HiRes'    => 0,
        'File::Spec'     => 0,
        'JSON::PP'       => 0,
    },

    TEST_REQUIRES => {
        'Test2::V0' => 0,
    },

    EXE_FILES => [],

    PM => {
        'lib/Concierge/Sessions.pm'             => '$(INST_LIB)/Concierge/Sessions.pm',
        'lib/Concierge/Sessions/Base.pm'        => '$(INST_LIB)/Concierge/Sessions/Base.pm',
        'lib/Concierge/Sessions/Session.pm'     => '$(INST_LIB)/Concierge/Sessions/Session.pm',
        'lib/Concierge/Sessions/SQLite.pm'      => '$(INST_LIB)/Concierge/Sessions/SQLite.pm',
        'lib/Concierge/Sessions/File.pm'        => '$(INST_LIB)/Concierge/Sessions/File.pm',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/bwva/Concierge-Sessions.git',
                web  => 'https://github.com/bwva/Concierge-Sessions',
            },
            bugtracker => {
                web => 'https://github.com/bwva/Concierge-Sessions/issues',
            },
        },
        provides => {
            'Concierge::Sessions' => {
                file    => 'lib/Concierge/Sessions.pm',
                version => 'v0.11.1',
            },
            'Concierge::Sessions::Base' => {
                file    => 'lib/Concierge/Sessions/Base.pm',
                version => 'v0.11.1',
            },
            'Concierge::Sessions::Session' => {
                file    => 'lib/Concierge/Sessions/Session.pm',
                version => 'v0.11.1',
            },
            'Concierge::Sessions::SQLite' => {
                file    => 'lib/Concierge/Sessions/SQLite.pm',
                version => 'v0.11.1',
            },
            'Concierge::Sessions::File' => {
                file    => 'lib/Concierge/Sessions/File.pm',
                version => 'v0.11.1',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Concierge-Sessions-*' },
);

sub MY::postamble {
    return <<'MAKE_FRAG';
cover :
	cover -test
MAKE_FRAG
}