use Module::Build;
Module::Build->new(
    module_name        => 'Acme::DRM',
    license            => 'perl',
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    sign               => 1,
)->create_build_script;

