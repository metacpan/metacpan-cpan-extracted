use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Data::ICal::TimeZone',
    'VERSION_FROM' => 'lib/Data/ICal/TimeZone.pm',
    'PREREQ_PM' => {
        'Class::Accessor'    => 0,
        'Class::ReturnValue' => 0,
        'Class::Singleton'   => 0,
        'Data::ICal'         => 0,
        'UNIVERSAL::require' => 0,

    },
);

