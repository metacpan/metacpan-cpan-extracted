use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::View::REST::YAML',
    AUTHOR    => 'Sebastian Riedel (sri@oook.de)',
    PREREQ_PM => {
        Catalyst => '2.99',
        YAML     => 0
    },
    VERSION_FROM => 'YAML.pm'
);
