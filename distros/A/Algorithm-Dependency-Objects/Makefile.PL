use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Algorithm::Dependency::Objects',
    'VERSION_FROM' => 'lib/Algorithm/Dependency/Objects.pm',
    'PREREQ_PM'    => {
        'Carp'         => '0',
        'Scalar::Util' => '1.10',
        'Set::Object'  => '0',
        'Test::Deep'   => '0',
        'Test::More'   => '0.47'
    },
    'INSTALLDIRS' => 'site',
    'EXE_FILES'   => [],
    'PL_FILES'    => {}
);
