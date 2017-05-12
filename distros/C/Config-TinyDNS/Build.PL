use Module::Build;

Module::Build->new(
    module_name     => "Config::TinyDNS",
    license         => "bsd",
    requires        => {
        perl                => "5.010",
        "File::Slurp"       => 0,
        "Exporter::NoWork"  => 0,
        "List::MoreUtils"   => 0,
    },
    build_requires  => {
        "Test::More"        => "0.65",
        "Test::Warn"        => 0,
        "Test::NoWarnings"  => "1.00",
        "Test::Exception"   => 0,
        "Test::Exports"     => 1,
    },
)->create_build_script;
