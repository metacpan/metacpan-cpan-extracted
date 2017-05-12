use Module::Build;
use lib './t/lib';
Module::Build->new(
    module_name => 'CGI::Application::Search',
    license => 'perl',
    requires => {
        'perl'                                    => '5.6.1',
        'CGI::Application'                        => 4.0,
        'Encode'                                  => 0,
        'Unicode::Normalize'                      => 0,
        'CGI::Application::Plugin::AnyTemplate'   => 0,
        'SWISH::API'                              => 0.04, # in swish-e 2.4.5
        'Search::Tools::HiLiter'                  => 0.12,
        'Data::Page'                              => 1.0,
        'File::Spec::Functions'                   => 0,
        'Number::Format'                          => 0,
        'HTML::FillInForm'                        => 1.04,
        'Time::HiRes'                             => 0,
        'Time::Piece'                             => 0,
        'POSIX'                                   => 0,
        'Text::Context'                           => 3.5,
        'File::Spec'                              => 0,
        'Capture::Tiny'                           => 0.06,
        'Cwd'                                     => 0,
        'File::Slurp'                             => 9999.13,
    },
    build_requires  => {
        'Test::LongString'                                               => 0,
        'Test::Class'                                                    => 0,
        'CGI::Application::Plugin::AnyTemplate::Driver::TemplateToolkit' => 0,
        'Template'                                                       => 0,
    },
    create_readme      => 1,
    pm_files => {
        'lib/CGI/Application/Search.pm'      => 'lib/CGI/Application/Search.pm',
        'templates/search_results.tmpl'      => 'lib/CGI/Application/Search/templates/search_results.tmpl',
        'templates/search_results.tt'        => 'lib/CGI/Application/Search/templates/search_results.tt',
        'templates/ajax_search_results.tmpl' => 'lib/CGI/Application/Search/templates/ajax_search_results.tmpl',
        'templates/ajax_search_results.tt'   => 'lib/CGI/Application/Search/templates/ajax_search_results.tt',
        'templates/prototype_javascript.tmpl'=> 'lib/CGI/Application/Search/templates/prototype_javascript.tmpl',
    },
    create_makefile_pl => 'passthrough',
)->create_build_script();
