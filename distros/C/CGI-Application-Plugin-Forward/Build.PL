use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Application::Plugin::Forward',
    license             => 'perl',
    dist_author         => 'Michael Graham <mag-perl@occamstoothbrush.com>',
    dist_version_from   => 'lib/CGI/Application/Plugin/Forward.pm',
    requires => {
        'CGI::Application' => 0,
        'Test::More'       => 0,
    },
    recommends => {
        'CGI::Application::Plugin::AutoRunmode' => 0.09,
    },
    add_to_cleanup      => [ 'CGI-Application-Plugin-Forward-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
