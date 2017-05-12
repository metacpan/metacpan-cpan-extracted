use strict;
use warnings;
use Module::Build;

use utf8;

my $builder = Module::Build->new(
    module_name       => 'CHI::Driver::TokyoTyrant',
    license           => 'perl',
    dist_abstract     => 'Use TokyoTyrant for cache storage',
    dist_author       => 'Jiří Pavlovský <jira@getnet.cz>',
    dist_version_from => 'lib/CHI/Driver/TokyoTyrant.pm',
    build_requires    => {
        'Test::More'  => 0,
        'CHI'         => 0,
        'Test::Class' => 0,
    },
    requires => {
        'TokyoTyrant' => 0,
        'CHI' => 0.241,
    },
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
