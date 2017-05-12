use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Algorithm::Merge',
    VERSION_FROM => 'Merge.pm',
    PREREQ_PM => {
        Algorithm::Diff => 1, # tested/developed with 1.15
        Test::More => 0,
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
