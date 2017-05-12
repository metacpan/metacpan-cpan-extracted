use Module::Build;
my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    module_name        => 'Business::DE::KontoCheck',
    license            => 'perl',
    dist_author        => 'Tina Mueller',
    requires => { },
    recommends         => { },
    recomends     => {},
    create_readme => 0,
    sign          => 0,
);
$build->create_build_script;

