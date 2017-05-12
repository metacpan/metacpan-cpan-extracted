use Module::Build;

Module::Build->new(
    'module_name' => 'CGI::Application::Plugin::Stream',
    license => 'perl',
    requires => {
        'Test::More'        =>  0,
        'File::Basename'	=>	1.0,
        'CGI::Application'	=>	3.21,
        'File::MMagic'      =>  0,
        'FileHandle'        =>  1.22,
    },
    create_makefile_pl => 'traditional',
    create_readme => 1,
    dist_author => 'Jason Purdy <Jason@Purdy.INFO>',
    dist_abstract => 'Plugin that adds file streaming support to CGI::Application',
)->create_build_script;

