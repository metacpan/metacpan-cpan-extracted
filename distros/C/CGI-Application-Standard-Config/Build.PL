use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Application::Standard::Config',
    license             => 'perl',
    dist_author         => 'Mark Stosberg <mark@summersault.com>',
    dist_version_from   => 'lib/CGI/Application/Standard/Config.pm',
    create_makefile_pl  => 'traditional',
    create_readme       => 1,
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'CGI-Application-Standard-Config-*' ],
);

$builder->create_build_script();
