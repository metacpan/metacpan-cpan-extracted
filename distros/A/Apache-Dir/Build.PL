use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Apache::Dir',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.2701' },
    recommends         => {
        'Test::Pod'     => '1.41',
        'mod_perl'      => 0,
    },
    build_requires     => {
        'Module::Build' => '0.2701',
        'Test::More'    => '0.17',
    },
);
$build->create_build_script;
