use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Config::Access::Driver',
    LICENSE          => 'perl',
    AUTHOR           => 'Bodo (Hugo) Barwich <b.barwich@hotmail.com>',
    VERSION_FROM     => 'lib/Config/Access/Driver.pm',
    MIN_PERL_VERSION => '5.010',
    test             => { TESTS => 't/*.t' },
    BUILD_REQUIRES   => {
        'ExtUtils::MakeMaker' => '6.55',
    },
    TEST_REQUIRES => {
        'Test::More'    => '0',
        'Test::Exception' => '0'
    },
    PREREQ_PM => {
        'File::Access::Driver'  => '0',
        'Object::Meta'  => '0',
        'Data::Dump'  => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/bodo-hugo-barwich/config-driver-pl.git',
                web  => 'https://github.com/bodo-hugo-barwich/config-driver-pl',
            },
            bugtracker => {
                web => 'https://github.com/bodo-hugo-barwich/config-driver-pl/issues'
            },
        },
    },
);

