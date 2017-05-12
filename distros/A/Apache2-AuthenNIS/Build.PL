use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Apache2::AuthenNIS',
    license             => 'perl',
    dist_author         => 'Nguon Hao Ching <hao@iteaha.us>',
    dist_version_from   => 'lib/Apache2/AuthenNIS.pm',
    build_requires      => {
        'Test::More' => 0,
    },
    requires            => {
        'Net::NIS'   => 0,
    },
    recommends          => {
        'mod_perl2'  => 0,
    },
    add_to_cleanup      => [ 'Apache2-AuthenNIS-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
