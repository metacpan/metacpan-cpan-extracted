use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'DBIx::Class::QueriesTime',
    'VERSION_FROM' => 'lib/DBIx/Class/QueriesTime.pm', # finds $VERSION
    'PREREQ_PM' => {
        Test::More  => 0.32,
        DBIx::Class => 0.05006,
        Time::HiRes => 0,
    },
);
