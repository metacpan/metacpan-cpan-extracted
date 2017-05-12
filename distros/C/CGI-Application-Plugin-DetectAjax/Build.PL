use Module::Build;

use utf8;

Module::Build->new(
    module_name => 'CGI::Application::Plugin::DetectAjax',
    license => 'perl',
    dist_version_from => 'lib/CGI/Application/Plugin/DetectAjax.pm',
    requires => {
        'CGI::Application' => 0,
        'Exporter' => 0,
    },
    build_requires    => {
      'Test::More'  => 0,
    },
    create_makefile_pl => 'traditional',
    dist_author => 'Jiří Pavlovský  <jira@getnet.cz>',
    dist_abstract => 'Plugin that adds XMLHttpRequest detection to CGI::Application',
)->create_build_script;

