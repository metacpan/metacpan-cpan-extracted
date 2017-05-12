use Module::Build;

Module::Build->new(
    module_name => 'CGI::Application::Plugin::TT',
    license => 'perl',
    requires => {
        'CGI::Application' => '4.0',
        'Template' => '2.0',
        'Scalar::Util' => 0,
        'File::Spec' => 0,
        'Class::ISA' => 0,
    },
    recommends => {
        'CGI::Application::Plugin::DevPopup' => 0,
    },
    create_makefile_pl => 'traditional',
    dist_author => 'Cees Hek <cees@crtconsulting.ca>',
    dist_abstract => 'Plugin that adds Template Toolkit support to CGI::Application',
)->create_build_script;

