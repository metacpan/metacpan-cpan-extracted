use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Closure::Loop',
    license             => 'perl',
    dist_author         => 'Andy Armstrong <andy@hexten.net>',
    dist_version_from   => 'lib/Closure/Loop.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Closure-Loop-*' ],
);

$builder->create_build_script();
