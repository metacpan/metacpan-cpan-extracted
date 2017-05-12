use Module::Build;

Module::Build->new(
    module_name => 'CGI::Application::Plugin::PageLookup',
    license => 'perl',
    requires => {
        'Carp' => 0,
        'CGI'=>0,
        'CGI::Application' => '4.31',
        'CGI::Application::Plugin::Forward' => 0,
        'CGI::Application::Plugin::DBH' => 0,
        'DBI' => 0,
        'HTML::Template'=>0,
        'HTML::Template::Pluggable'=>0,
        'UNIVERSAL::require'=>0,
    },
    recommends => {
    },
    build_requires => {
        'Test::Differences' => 0,
        'Test::More' => 0,
        'Test::Database' => '1.07',
        'XML::LibXML'=>0
    },
    meta_merge => {
        resources=> {
            repository => 'http://github.com/periapt/cgi-application-plugin-pagelookup/tree',
        },
        keywords => ['cgiapp','Titanium','framework','sitemap'],
    },
    create_makefile_pl => 'traditional',
    dist_author => q{Nicholas Bamber <nicholas@periapt.co.uk>},
)->create_build_script;

