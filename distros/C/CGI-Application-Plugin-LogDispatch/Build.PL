use Module::Build;

Module::Build->new(
    module_name => 'CGI::Application::Plugin::LogDispatch',
    license => 'perl',
    requires => {
        'CGI::Application' => 0,
        'Log::Dispatch' => '0.21',
        'UNIVERSAL::require' => 0,
        'Scalar::Util' => 0,
    },
    recommends => {
        'Sub::WrapPackages' => 0,
        'Class::ISA' => 0,
    },
    create_makefile_pl => 'traditional',
    dist_author => 'Cees Hek <ceeshek@gmail.com>',
    dist_abstract => 'Plugin that adds Log::Dispatch support to CGI::Application',
)->create_build_script;

