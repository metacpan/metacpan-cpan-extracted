use Module::Build;

my $build = Module::Build->new(
    module_name         => 'Attribute::Method::Tags',
    license             => 'perl',
    requires            => {
        'Attribute::Handlers'   => 0.77,
        'Test::More'            => 0.78,
    },
    create_makefile_pl  => 'traditional',
    create_readme       => 1,
);

$build->create_build_script;
