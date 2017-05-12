use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Config::Context',
    license             => 'perl',
    dist_author         => 'Michael Graham <mag-perl@occamstoothbrush.com>',
    dist_version_from   => 'lib/Config/Context.pm',
    requires => {
        'Test::More'      => 0,
        'Clone'           => 0,
        'Hash::Merge'     => 0,
        'Config::General' => 2.27,
    },
    add_to_cleanup      => [ 'Config-Context-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
