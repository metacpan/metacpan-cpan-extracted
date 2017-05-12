use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Acme::Magpie',
    VERSION_FROM => 'lib/Acme/Magpie.pm',
    PREREQ_PM    => {
        'Test::More'     => 0,
        'Devel::Symdump' => 0
    }
);
