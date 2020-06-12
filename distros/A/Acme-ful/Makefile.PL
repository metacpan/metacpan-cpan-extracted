use ExtUtils::MakeMaker;

WriteMakefile(
    ABSTRACT => 'A nifty "find upper lib" pragma',
    AUTHOR => 'Ryan Willis <code@ryanwillis.com>',
    LICENSE => 'mit',
    MIN_PERL_VERSION => '5.26.1',
    META_MERGE => {
        'meta-spec'    => { version => 2 },
        dynamic_config => 1,
        provides => {
            'Acme::ful' => {
                file => 'lib/Acme/ful.pm',
                version => '0.07',
            },
            'ful' => {
                file => 'lib/ful.pm',
                version => '0.07',
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'git://github.com/ryan-willis/p5-Acme-ful.git',
                web  => 'https://github.com/ryan-willis/p5-Acme-ful',
            },
        },
    },
    PREREQ_PM => {
        'strict'     => 0,
        'warnings'   => 0,
        'Cwd'        => '3.26',
        'File::Spec' => '3.32',
    },
    TEST_REQUIRES => {
        'Test::Most' => '0.30',
    },
    NAME => 'Acme::ful',
    DISTNAME => 'Acme-ful',
    VERSION_FROM => 'lib/ful.pm',
    test => { TESTS => 't/*.t t/t2/*.t t/t2/t3/*.t t/t2/t3/t/*.t' },
    dist => { TAR => 'gtar', COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);