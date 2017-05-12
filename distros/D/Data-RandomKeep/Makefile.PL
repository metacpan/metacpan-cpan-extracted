use 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Data::RandomKeep',
    VERSION_FROM  => 'lib/Data/RandomKeep.pm',
    PREREQ_PM     => {
        Test::Usage => 0,
    },
    ABSTRACT_FROM  => 'lib/Data/RandomKeep.pm',
    AUTHOR         => 'Luc St-Louis <lucs@cpan.org>',
);

