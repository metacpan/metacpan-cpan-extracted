use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Data::FDSet',
    VERSION_FROM   => 'lib/Data/FDSet.pm',
    ABSTRACT_FROM  => 'lib/Data/FDSet.pm',
    AUTHOR         => 'Felipe Gasper (FELIPE)',
    LICENSE        => 'perl',

    PREREQ_PM => {
    },

    TEST_REQUIRES => {
        'Test::More'            => 0,
        'Test::FailWarnings'    => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/FGasper/p5-Data-FDSet/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/FGasper/p5-Data-FDSet.git',
                web  => 'https://github.com/FGasper/p5-Data-FDSet',
            },
        },
    },
);
