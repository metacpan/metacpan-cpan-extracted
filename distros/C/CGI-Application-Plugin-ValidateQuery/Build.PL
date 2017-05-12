use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Application::Plugin::ValidateQuery',
    license             => 'perl',
    dist_author         => 'Nathaniel K Smith <nate@summersault.com>',
    dist_version_from   => 'lib/CGI/Application/Plugin/ValidateQuery.pm',
    build_requires => {
        'Test::More'       => 0,
        'CGI::Application' => 3.31,
    },
    requires       => {
        'Params::Validate' => 0,
    },
    add_to_cleanup      => [ 'CGI-Application-Plugin-ValidateQuery-*' ],
);

$builder->create_build_script();
