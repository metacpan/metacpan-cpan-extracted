use Module::Build;

Module::Build->new(
    module_name => 'CGI::Application::Plugin::ConfigAuto',
    license => 'perl',
    requires => {
        'CGI::Application' => 0,
        'Config::Auto'     => 0,
        'Carp'             => 0,
    },
    create_makefile_pl => 'traditional',
    create_readme => 1,
    dist_author => 'Mark Stosberg <mark@summersault.com>',
    dist_abstract => 'Plugin that adds Config::Auto support to CGI::Application',
)->create_build_script;

