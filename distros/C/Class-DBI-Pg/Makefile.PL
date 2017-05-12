use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Class::DBI::Pg',
    'VERSION_FROM' => 'Pg.pm',
    'PREREQ_PM'    => {
        Test::More => 0.32,
        DBD::Pg    => 1.13,
        Class::DBI => 0.89
    },
);
