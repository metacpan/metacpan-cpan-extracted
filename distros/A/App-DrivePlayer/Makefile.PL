use strict;
use warnings;

use 5.024000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'App::DrivePlayer',
    AUTHOR        => 'Robin Murray <mvsjes@cpan.org>',
    ABSTRACT_FROM => 'lib/App/DrivePlayer.pm',
    VERSION_FROM  => 'lib/App/DrivePlayer.pm',
    EXE_FILES     => ['bin/drive_player'],
    PREREQ_PM     => {
        'DBD::SQLite'      => 0,
        'DBIx::Class'      => 0,
        'Glib'             => 0,
        'Gtk3'             => 0,
        'Google::RestApi'  => '2.2.2',
        'JSON::MaybeXS'    => 0,
        'Log::Log4perl'    => 0,
        'Moo'              => 0,
        'Readonly'         => 0,
        'SQL::Translator'  => '0.11018',
        'ToolSet'          => 0,
        'Type::Tiny'       => 0,
        'URI'              => 0,
        'YAML'             => 0,
        'YAML::XS'         => 0,
    },
    TEST_REQUIRES => {
        'Mock::MonkeyPatch'  => 0,
        'Module::Load'       => 0,
        'Test::Class'        => 0,
        'Test::Class::Load'  => 0,
        'Test::Compile'      => 0,
        'Test::Most'         => 0,
        # Test::Pod / Test::Perl::Critic are author-only tests, gated by
        # AUTHOR_TESTING in t/pod.t and t/perlcritic.t.
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://github.com/mvsjes2/drive_player',
            bugtracker => {
                web => 'https://github.com/mvsjes2/drive_player/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/mvsjes2/drive_player.git',
                web  => 'https://github.com/mvsjes2/drive_player',
            },
        },
    },
    LICENSE => 'mit',
);
