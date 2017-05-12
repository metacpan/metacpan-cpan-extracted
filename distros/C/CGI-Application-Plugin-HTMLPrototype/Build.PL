use Module::Build;

Module::Build->new(
    module_name => 'CGI::Application::Plugin::HTMLPrototype',
    license => 'perl',
    requires => {
        'CGI::Application' => '3.0',
        'HTML::Prototype' => 0,
    },
    create_makefile_pl => 'traditional',
    dist_author => 'Cees Hek <ceeshek@gmail.com>',
    dist_abstract => 'Give easy access to the prototype JavaScript library using HTML::Prototype',
)->create_build_script;

