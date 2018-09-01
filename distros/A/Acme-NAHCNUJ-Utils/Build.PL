use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::NAHCNUJ::Utils',
    license             => 'artistic_2',
    dist_author         => q{Junichi Hayashi <j-hayasi@ist.osaka-u.ac.jp>},
    dist_version_from   => 'lib/Acme/NAHCNUJ/Utils.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More' => '0',
    },
    requires => {
    },
    add_to_cleanup     => [ 'Acme-NAHCNUJ-Utils-*' ],
);

$builder->create_build_script();
