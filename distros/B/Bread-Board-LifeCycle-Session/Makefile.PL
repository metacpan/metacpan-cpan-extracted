use ExtUtils::MakeMaker;
WriteMakefile
(
    PL_FILES     => {},
    INSTALLDIRS  => 'site',
    NAME         => 'Bread::Board::LifeCycle::Session',
    EXE_FILES    => [],
    VERSION_FROM => 'lib/Bread/Board/LifeCycle/Session.pm',
    PREREQ_PM    => {
        'Moose'        => 0,
        'namespace::autoclean' => 0,
        'Module::Runtime' => 0,
        'Bread::Board' => 0,
        'List::Util'   => '1.33',
    },
    TEST_REQUIRES => {
        'Test::More'   => 0,
        'Test::Fatal'  => 0,
    },
);
