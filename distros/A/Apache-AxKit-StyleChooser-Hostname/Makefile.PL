use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Apache::AxKit::StyleChooser::Hostname',
    'VERSION_FROM' => 'Hostname.pm',
    'PREREQ_PM'    => {
        AxKit => 0,
    },
);
