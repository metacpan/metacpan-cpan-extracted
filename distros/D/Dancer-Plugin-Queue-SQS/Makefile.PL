use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Dancer::Plugin::Queue::SQS',
    VERSION_FROM => 'lib/Dancer/Plugin/Queue/SQS.pm', # finds \$VERSION
    AUTHOR       => 'Colin Ewen (colin@draecas.com)',
    ABSTRACT     => 'SQS Adapter for Dancer::Plugin::Queue',
    LICENSE          => 'artistic_2',
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Dancer' => 0,
        'Amazon::SQS::Simple' => '2.03',
        'Moo' => '2.000001',
        'namespace::autoclean' => 0,
        'Dancer::Plugin::Queue' => '0.002'
    },
    TEST_REQUIRES => {
        'YAML' => 0,
        'JSON' => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer-Plugin-Queue-SQS-*' },
);

