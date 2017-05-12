use Module::Build;

Module::Build->new(
    module_name => 'CGI::Application::Plugin::Authorization',
    license => 'perl',
    requires => {
        'CGI::Application' => 4,
        'Class::ISA' => 0,
        'UNIVERSAL::require' => 0,
    },
    recommends => {
        'CGI::Application::Plugin::Authentication' => 0,
        'Apache::Htgroup' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Test::Warn' => 0,
        'Test::Exception' => 0,
    },
    create_makefile_pl => 'traditional',
    dist_author => 'Cees Hek <ceeshek@gmail.com>',
    add_to_cleanup => [qw(t/sqlite.db)],
)->create_build_script;

