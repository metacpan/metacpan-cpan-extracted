use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::Plugin::Static',
    AUTHOR    => 'Sebastian Riedel (sri@oook.de)',
    PREREQ_PM => {
        Catalyst         => '2.99',
        'File::MimeInfo' => '0.11',
        'File::Slurp'    => 0,
        'MRO::Compat'    => 0,
    },
    VERSION_FROM => 'lib/Catalyst/Plugin/Static.pm'
);
