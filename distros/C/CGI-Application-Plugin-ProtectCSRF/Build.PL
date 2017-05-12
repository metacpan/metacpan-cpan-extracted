use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Application::Plugin::ProtectCSRF',
    license             => 'perl',
    dist_author         => 'Akira Horimoto <kurt0027@gmail.com>',
    dist_version_from   => 'CGI/Application/Plugin/ProtectCSRF.pm',
    requires => {
        "Attribute::Handlers"               => 0.78,
        "CGI::Application"                  => 4.04,
        "CGI::Application::Plugin::Session" => 1.01,
        "Digest::SHA1"                      => 2.07,
    },
    add_to_cleanup      => [ 'CGI-Application-Plugin-ProtectCSRF-*' ],
);

$builder->create_build_script();
