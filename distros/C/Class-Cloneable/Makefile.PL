use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Class::Cloneable',
    VERSION_FROM => 'lib/Class/Cloneable.pm', 
    PREREQ_PM    => {
        'Test::More'   => 0.47,
        'Scalar::Util' => 1.18
    }
);
