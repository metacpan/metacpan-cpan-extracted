use 5.010001;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'DR::DateTime',
    VERSION_FROM      => 'lib/DR/DateTime.pm',
    PREREQ_PM         => {
        'Time::Zone'            => 0,
        'Time::Local'           => 0,
    },
    ABSTRACT_FROM     => 'lib/DR/DateTime.pm',
    AUTHOR            => 'Dmitry E. Oboukhov <unera@debian.org>',
    LICENSE           => 'perl',
);
