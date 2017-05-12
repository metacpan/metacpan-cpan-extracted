use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Class::Std::Storable',
    license             => 'perl',
    dist_author         => 'Luke Meyer <luke@daeron.com>',
    dist_version_from   => 'lib/Class/Std/Storable.pm',
    requires => {
        'Class::Std' => '0.0.4',
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Class-Std-Storable-*' ],
);

$builder->create_build_script();
