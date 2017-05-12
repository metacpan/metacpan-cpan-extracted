use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Class::Delegator',
    license            => 'perl',
    configure_requires => { 'Module::Build' => '0.2701' },
    recommends         => { 'Test::Pod'     => '1.20'   },
    build_requires     => {
        'Module::Build' => '0.2701',
        'Test::More'    => '0.17',
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
);
$build->create_build_script;
