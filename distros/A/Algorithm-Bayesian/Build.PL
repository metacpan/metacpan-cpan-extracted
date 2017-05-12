use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Algorithm::Bayesian',
    license             => 'perl',
    dist_author         => q{Gea-Suan Lin <gslin@gslin.org>},
    dist_version_from   => 'lib/Algorithm/Bayesian.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
	'Math::BigFloat' => 0,
    },
    add_to_cleanup      => [ 'Algorithm-Bayesian-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
