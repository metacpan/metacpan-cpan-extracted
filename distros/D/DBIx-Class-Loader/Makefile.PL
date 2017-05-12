use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'DBIx::Class::Loader',
    'VERSION_FROM' => 'lib/DBIx/Class/Loader.pm',
    'PREREQ_PM'    => {
        Test::More          => 0.32,
        DBIx::Class         => 0.04001,
        DBI                 => 1.30,
        Lingua::EN::Inflect => 0,
        Text::Balanced      => 0,
        UNIVERSAL::require  => 0.10,
    },
);
