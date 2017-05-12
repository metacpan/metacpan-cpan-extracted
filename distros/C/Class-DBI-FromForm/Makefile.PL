use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Class::DBI::FromForm',
    'VERSION_FROM' => 'FromForm.pm',
    'PREREQ_PM'    => {
        Class::DBI          => 0,
        Data::FormValidator => 0
    },
);
