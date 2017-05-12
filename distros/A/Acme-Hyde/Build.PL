use strict;
use warnings;
use Module::Build;
use inc::Module::Install;

my $builder = Module::Build->new(
    module_name         => 'Acme::Hyde',
    license             => 'perl',
    dist_author         => 'Tetsunari Nozaki <nozzzzz@gmail.com>',
    dist_version_from   => 'lib/Acme/Hyde.pm',
    requires => {
        'Test::More' => 0,
        'Test::Base' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Acme-Hyde-*' ],
);

$builder->create_build_script();
