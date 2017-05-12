use strict;
use warnings;
use Module::Build;
use lib './t/lib';

my $builder = Module::Build->new(
    module_name => 'CGI::Application::Plugin::JSON',
    license     => 'perl',
    dist_author => 'Michael Peters <mpeters@plusthree.com>',
    requires    => {
        'Test::More'       => 0,
        'CGI::Application' => 4.00,
        'JSON::Any'        => 1.14,
    },
    build_requires => {JSON => '2.02'},
    create_readme  => 1,
);

$builder->create_build_script();
