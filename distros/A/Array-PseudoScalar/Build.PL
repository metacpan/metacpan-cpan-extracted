use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Array::PseudoScalar',
    license             => 'perl',
    dist_author         => q{Laurent Dami <dami@cpan.org>},
    dist_version_from   => 'lib/Array/PseudoScalar.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'Array-PseudoScalar-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
