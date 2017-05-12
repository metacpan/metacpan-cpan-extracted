
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'CSS::Compressor',
    VERSION_FROM   => 'Compressor.pm',
    PREREQ_PM      => {},
    BUILD_REQUIRES => {
        'Test::Differences' => 0,
    },
    ABSTRACT_FROM  => 'Compressor.pm',
    AUTHOR         => 'Simon Bertrang <janus@cpan.org>',
);

