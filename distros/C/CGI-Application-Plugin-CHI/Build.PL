use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Application::Plugin::CHI',
    license             => 'perl',
    dist_author         => 'Mike Friedman <friedo@friedo.com>',
    dist_version_from   => 'lib/CGI/Application/Plugin/CHI.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires       => { 
        'CGI::Application'  => 0,
        'CHI'               => 0,
        'Scalar::Util'      => 0,
    },
    add_to_cleanup      => [ 'CGI-Application-Plugin-CHI-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
