use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Catalyst::Authentication::Store::FromSub::Hash',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Catalyst/Authentication/Store/FromSub/Hash.pm',
    build_requires => {
        'Test::More' => 0,
        'Catalyst'   => 0,
        'Catalyst::Plugin::Authentication' => '0.10004',
    },
    add_to_cleanup      => [ 'Catalyst-Authentication-Store-FromSub-Hash-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
