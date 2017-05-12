use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'          => 'Algorithm::Knapsack',
    'VERSION_FROM'  => 'lib/Algorithm/Knapsack.pm',
    'EXE_FILES'     => [ 'bin/filesack' ],
);
