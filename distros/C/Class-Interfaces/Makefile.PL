use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Class::Interfaces',
    VERSION_FROM => 'lib/Class/Interfaces.pm', 
    PREREQ_PM    => {
        'Test::More' => 0.47,
    }
);
