use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Application::Plugin::AnyCGI',
    license             => 'perl',
    dist_author         => 'Bianka Martinovic <mab@cpan.org>',
    dist_version_from   => 'lib/CGI/Application/Plugin/AnyCGI.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'CGI-Application-Plugin-AnyCGI-*' ],
);

$builder->create_build_script();
