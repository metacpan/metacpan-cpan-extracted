use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Application::Plugin::Authentication::Driver::DBIC',
    license             => 'perl',
    dist_author         => 'Jaldhar H. Vyas <jaldhar@braincells.com>',
    dist_version_from   => 'lib/CGI/Application/Plugin/Authentication/Driver/DBIC.pm',
    build_requires => {
        'CGI'                                      => 0,
        'CGI::Application::Plugin::Authentication' => 0.06,
        'DBIx::Class'                              => 0,
        'File::Path'                               => 0,
        'Test::More'                               => 0,
    },
    recommends => {
        'CGI::Application::Plugin::Session'        => 0,
        'DBD::SQLite'                              => 0,
        'Digest::MD5'                              => 0,
        'Module::Signature'                        => 0,
        'Test::Pod'                                => 1.14,
        'Test::Pod::Coverage'                      => 1.04,
    },
    requires => {
        'CGI::Application::Plugin::Authentication' => 0.06,
        'DBIx::Class'                              => 0,
    },
    add_to_cleanup      => [ 'CGI-Application-Plugin-Authentication-Driver-DBIC-*' ],
    create_makefile_pl => 'traditional',
    sign => 1,
);

$builder->create_build_script();
