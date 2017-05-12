use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Class::DBI::Loader',
    'VERSION_FROM' => 'lib/Class/DBI/Loader.pm',
    'PREREQ_PM'    => {
        Test::More          => 0.32,
        Class::DBI          => 0.89,
        DBI                 => 1.30,
        Lingua::EN::Inflect => 0,
        Text::Balanced      => 0
    },
);
