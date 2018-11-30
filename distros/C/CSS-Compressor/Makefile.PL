
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
    META_MERGE     => {
        resources      => {
            license        => 'http://dev.perl.org/licenses/',
            repository     => 'https://github.com/sbertrang/css-compressor.git',
            bugtracker     => 'https://github.com/sbertrang/css-compressor/issues',
        },
    },
);

