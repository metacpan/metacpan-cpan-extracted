use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Class::StrongSingleton',
    VERSION_FROM => 'lib/Class/StrongSingleton.pm', 
    PREREQ_PM    => {
        'Test::More' => 0.47,
    }
);
