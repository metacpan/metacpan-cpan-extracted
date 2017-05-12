use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CPAN::Mini::Inject::Server',
    license             => 'perl',
    dist_author         => q{Christopher Mckay <potatohead@potatolan.com>},
    dist_version_from   => 'lib/CPAN/Mini/Inject/Server.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'CGI::Application' => 0,
        'CGI::Application::Plugin::AutoRunmode' => 0,
        'CPAN::Mini::Inject' => 0,
        'CGI::Application::Dispatch' => 0,
    },
    recommends => {
        'Getopt::Long' => 0,
        'Pod::Usage' => 0,
        'CGI::Application::Dispatch::Server' => 0,
    },
    add_to_cleanup      => [ 'CPAN-Mini-Inject-Server-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
