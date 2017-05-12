use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Algorithm::LCSS',
    'VERSION_FROM'  => 'LCSS.pm',
    'PREREQ_PM'     => {Algorithm::Diff => 1.1},
);
