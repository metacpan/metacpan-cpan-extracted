use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Application::Plugin::Config::Context',
    license             => 'perl',
    dist_author         => 'Michael Graham <mag-perl@occamstoothbrush.com>',
    dist_version_from   => 'lib/CGI/Application/Plugin/Config/Context.pm',
    requires => {
        'Test::More'       => 0,
        'Config::Context'  => 0.06,
        'CGI::Application' => 0,
    },
    add_to_cleanup      => [ 'CGI-Application-Plugin-Config-Context-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
