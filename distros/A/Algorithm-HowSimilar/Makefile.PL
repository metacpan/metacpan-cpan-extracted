use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'        => 'Algorithm::HowSimilar',
    'VERSION_FROM'    => 'HowSimilar.pm',
    'PREREQ_PM'        => { Algorithm::Diff => 1.0 },

);
