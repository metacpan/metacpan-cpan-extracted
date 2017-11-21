use ExtUtils::MakeMaker;
WriteMakefile(
    NAME             => "Dancer2::Plugin::OpenAPIRoutes",
    AUTHOR           => "Anton Petrusevich",
    VERSION          => "0.03",
    INSTALLDIRS      => 'site',
    LICENSE          => "artistic_2",
    MIN_PERL_VERSION => "5.010000",
    META_MERGE       => {
        "meta-spec" => {version => 2},
        resources   => {
            bugtracker => {web => 'https://github.com/jef-sure/d2-oar/issues'},
            repository => {
                type => 'git',
                url  => 'https://github.com/jef-sure/d2-oar.git',
                web  => 'https://github.com/jef-sure/d2-oar',
            },
        },
    },
    PREREQ_PM => {
        'File::Spec'    => 0,
        'Dancer2'       => 0,
        'Module::Load'  => 0,
        'JSON'          => 0,
        'JSON::Pointer' => 0,
        'YAML::XS'      => 0,
        'Data::Walk'    => 0,
    },
    TEST_REQUIRES => {
        'Test::Most' => 0,
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
