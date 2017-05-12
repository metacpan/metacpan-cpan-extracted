use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Algorithm::Kuhn::Munkres',
    license             => 'perl',
    dist_author         => 'Martin-Louis Bright <mlbright@gmail.com>',
    dist_version_from   => 'lib/Algorithm/Kuhn/Munkres.pm',
    requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Algorithm-Kuhn-Munkres-*' ],
);

$builder->create_build_script();
