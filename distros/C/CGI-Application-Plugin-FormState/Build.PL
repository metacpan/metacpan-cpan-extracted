use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Application::Plugin::FormState',
    license             => 'perl',
    dist_author         => 'Michael Graham <mag-perl@occamstoothbrush.com>',
    dist_version_from   => 'lib/CGI/Application/Plugin/FormState.pm',
    requires => {
        'Test::More'                        => 0,
        'CGI::Session'                      => 4.0,
        'CGI::Application::Plugin::Session' => 0.09,
        'CGI::Application'                  => 4.0,
        'CGI'                               => 2.37,
    },
    add_to_cleanup      => [ 'CGI-Application-Plugin-FormState-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
