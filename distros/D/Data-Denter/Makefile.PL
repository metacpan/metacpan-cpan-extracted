use ExtUtils::MakeMaker;
WriteMakefile(
    NAME	 => 'Data::Denter',
    VERSION_FROM => 'Denter.pm',
    PREREQ_PM    => {YAML => 0},
);
