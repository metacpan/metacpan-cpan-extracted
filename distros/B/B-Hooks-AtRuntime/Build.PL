use Module::Build;

Module::Build->new(
    module_name         => "B::Hooks::AtRuntime",
    license             => "bsd",

    include_dirs        => ".",

    configure_requires  => {
        "Module::Build"     => "0.38",
    },
    build_requires      => {
        "Test::More"        => "1.001002",
        "Test::Exception"   => "0.31",
        "Test::Warn"        => "0.22",
        "Test::Exports"     => "1",
    },
    requires            => {
        perl                => "5.008001",
        "Exporter::Tiny"    => 0,
        "Sub::Name"         => "0.05",
        "Filter::Util::Call"    => "0",
        "parent"            => 0,
    },

    meta_merge          => {
        resources => {
            repository => "http://github.com/mauzo/B-Hooks-AtRuntime",
            bugtracker => "https://rt.cpan.org/Public/Dist/" .
                "Display.html?Name=B-Hooks-AtRuntime",
        },
    },
)->create_build_script;
