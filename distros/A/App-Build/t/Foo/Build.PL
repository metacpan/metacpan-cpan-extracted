
use App::Build;

my $build = App::Build->new (
    module_name       => "Foo",
    dist_version      => "0.99",
    dist_author       => "stephen.adkins\@officevision.com",
    dist_abstract     => "A test Build.PL",
    license           => "perl",
    requires => {
        "App::Options"   => 0,
    },
    build_requires => {
        "App::Build"     => 0,
    },
    extra_dirs => [ "cgi-bin", "htdocs", "lib", ],
    dynamic_config => 1,
    install_base => '../test_install/simple',
    create_packlist => 0,
);

$build->create_build_script;

