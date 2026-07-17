use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Concierge::Users',
    VERSION_FROM     => 'lib/Concierge/Users.pm',
    AUTHOR           => 'Bruce Van Allen <bva@cruzio.com>',
    ABSTRACT         => 'Dedicated user data management system with multiple storage backends',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.036',
    PREREQ_PM => {
        'Carp'       => 0,
        'JSON::PP'   => 0,
        'File::Path' => 0,
        'File::Spec' => 0,
        'DBI'        => 0,
        'DBD::SQLite' => 0,
        'Text::CSV'  => 0,
        'YAML::Tiny' => 0,
    },

    TEST_REQUIRES => {
        'Test2::V0'     => 0,
        'Capture::Tiny' => 0,
    },

    EXE_FILES => [],

    PM => {
        'lib/Concierge/Users.pm'          => '$(INST_LIB)/Concierge/Users.pm',
        'lib/Concierge/Users/Meta.pm'     => '$(INST_LIB)/Concierge/Users/Meta.pm',
        'lib/Concierge/Users/Database.pm' => '$(INST_LIB)/Concierge/Users/Database.pm',
        'lib/Concierge/Users/File.pm'     => '$(INST_LIB)/Concierge/Users/File.pm',
        'lib/Concierge/Users/YAML.pm'     => '$(INST_LIB)/Concierge/Users/YAML.pm',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/bwva/Concierge-Users.git',
                web  => 'https://github.com/bwva/Concierge-Users',
            },
            bugtracker => {
                web => 'https://github.com/bwva/Concierge-Users/issues',
            },
        },
        provides => {
            'Concierge::Users' => {
                file    => 'lib/Concierge/Users.pm',
                version => 'v0.9.3',
            },
            'Concierge::Users::Meta' => {
                file    => 'lib/Concierge/Users/Meta.pm',
                version => 'v0.9.3',
            },
            'Concierge::Users::Database' => {
                file    => 'lib/Concierge/Users/Database.pm',
                version => 'v0.9.3',
            },
            'Concierge::Users::File' => {
                file    => 'lib/Concierge/Users/File.pm',
                version => 'v0.9.3',
            },
            'Concierge::Users::YAML' => {
                file    => 'lib/Concierge/Users/YAML.pm',
                version => 'v0.9.3',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Concierge-Users-*' },
);

sub MY::postamble {
    return <<'MAKE_FRAG';
cover :
	cover -test
MAKE_FRAG
}