use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Class::Printable',
    VERSION_FROM => 'lib/Class/Printable.pm', 
    PREREQ_PM    => {
        'Test::More' => 0.47,
    }
);
