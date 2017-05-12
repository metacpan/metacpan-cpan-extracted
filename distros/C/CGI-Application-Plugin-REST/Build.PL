use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    dist_name           => 'CGI-Application-Plugin-REST',
    module_name         => 'CGI::Application::Plugin::REST',
    dist_abstract       => 'Helps implement RESTful architecture in CGI applications',
    dist_author         => 'Jaldhar H. Vyas <jaldhar@braincells.com>',
    license             => 'perl',
    dist_version_from   => 'lib/CGI/Application/Plugin/REST.pm',
    build_requires => {
        'CGI::Application::Plugin::DevPopup' => 0,
        'Test::WWW::Mechanize::CGIApp'       => 0,
        'Test::LongString'                   => 0,
    },
    requires => {
        'perl'                          => 5.008,
        'CGI::Application'              => 4.04,
        'REST::Utils'                   => 0.4,
    },
    add_to_cleanup      => [ 'CGI-Application-Plugin-REST-*' ],
    create_makefile_pl  => 'traditional',
    sign                => 1,
    meta_merge => {
            resources => {
                repository  => 'http://github.com/jaldhar/CGI-Application-Plugin-REST',
                homepage    => 'http://jaldhar.github.com/CGI-Application-Plugin-REST',
            },
    },
);

$builder->create_build_script();
