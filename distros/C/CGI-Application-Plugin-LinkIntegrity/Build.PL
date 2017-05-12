use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Application::Plugin::LinkIntegrity',
    license             => 'perl',
    dist_author         => 'Michael Graham <mag-perl@occamstoothbrush.com>',
    dist_version_from   => 'lib/CGI/Application/Plugin/LinkIntegrity.pm',
    requires => {
        'Test::More'       => 0,
        'CGI::Application' => 4.0,  # need hooks
        'URI'              => 0,
        'URI::Escape'      => 0,  # included in URI
        'URI::QueryParam'  => 0,  # included in URI
        'Digest::HMAC'     => 0,
        'Digest::MD5'      => 0,
        'CGI'              => 2.37,
    },
    add_to_cleanup      => [ 'CGI-Application-Plugin-LinkIntegrity-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
