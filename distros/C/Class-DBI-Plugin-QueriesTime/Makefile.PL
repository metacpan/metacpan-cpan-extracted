use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Class::DBI::Plugin::QueriesTime',
    'VERSION_FROM' => 'lib/Class/DBI/Plugin/QueriesTime.pm', # finds $VERSION
    'PREREQ_PM' => {
        Test::More  => 0.32,
        Class::DBI  => 0,
        Time::HiRes => 0,
    },
);
