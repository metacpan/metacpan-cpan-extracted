use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Class::Std::Fast',
    license            => 'perl',
    dist_author        => q{Andreas 'ac0v' Specht - ACID@cpan.org},
    dist_version_from  => 'lib/Class/Std/Fast.pm',
    create_makefile_pl => 'traditional',
    requires => {
        'version'      => 0,
        'Scalar::Util' => 0,
        'Data::Dumper' => 0,
        'Class::Std'   => '0.0.8',
    },
    build_requires => {
        'Test::More'   => 0,
    },
    add_to_cleanup      => [ 'Class-Std-*' ],
);

$builder->create_build_script();
