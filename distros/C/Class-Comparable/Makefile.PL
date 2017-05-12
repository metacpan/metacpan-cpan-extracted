use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Class::Comparable',
    VERSION_FROM => 'lib/Class/Comparable.pm', 
    PREREQ_PM    => {
        'Test::More' => 0.47,
    }
);
