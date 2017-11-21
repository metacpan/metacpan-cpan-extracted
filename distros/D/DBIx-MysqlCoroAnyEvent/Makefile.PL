use ExtUtils::MakeMaker;
WriteMakefile(
    NAME             => "DBIx::MysqlCoroAnyEvent",
    AUTHOR           => "Anton Petrusevich",
    VERSION          => "0.02",
    INSTALLDIRS      => 'site',
    LICENSE          => "artistic_2",
    MIN_PERL_VERSION => "5.014000",
    META_MERGE       => {
        "meta-spec" => {version => 2},
        resources   => {
            bugtracker => {web => 'https://github.com/jef-sure/dbd-mysql-cae/issues'},
            repository => {
                type => 'git',
                url  => 'https://github.com/jef-sure/dbd-mysql-cae.git',
                web  => 'https://github.com/jef-sure/dbd-mysql-cae',
            },
        },
    },
    PREREQ_PM => {
        'DBD::mysql'     => "4.019",
        'Coro'           => 0,
        'AnyEvent'       => 0,
        'Coro::AnyEvent' => 0,
    },
    TEST_REQUIRES => {
        'Test::More'   => 0,
        'DBI'          => 0,
        'Test::mysqld' => 0,
        'Time::HiRes'  => 0,
    },
    test => {TESTS => "t/*.t"},
    dist => {
        DIST_DEFAULT => 'all tardist',
        COMPRESS     => 'gzip -vf',
        SUFFIX       => '.gz',
    },
    clean     => {FILES => '*~',},
    realclean => {FILES => '*~',},
);
