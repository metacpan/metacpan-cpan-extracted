use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => "Bot::BasicBot::Pluggable::Module::Notes",
    VERSION_FROM => "lib/Bot/BasicBot/Pluggable/Module/Notes.pm",
    PREREQ_PM    => { 
        # FIXME: strictly speaking, these are optional.
        Web::Simple              => '0.02',
        JSON                     => '0',

        # FIXME: tests require both, but for running, either is sufficent.
        DBD::SQLite              => 0,
        DBIx::Class              => '0.08121',

        # really required.
        Bot::BasicBot::Pluggable => '0.74',
        File::Spec::Functions    => 0,
        Carp                     => 0,
        Test::DatabaseRow        => 0,
        Test::More               => 0,
        Time::Piece              => 0,
    },
    clean        => { FILES => "t/brane.db" }
);

