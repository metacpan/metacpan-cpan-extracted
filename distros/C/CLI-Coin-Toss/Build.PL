use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CLI::Coin::Toss',
    license             => 'gpl3',
    dist_author         => q{"Toshiyuki Shimono" <bin4tsv@gmail.com>},
    dist_version_from   => 'lib/CLI/Coin/Toss.pm',
    release_status      => 'stable',
    script_files        => [map{"scripts/$_"}qw[randexp quantile entropy cointoss cauchydist saikoro poisson boxmuller matrixpack]],
    configure_requires => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More' => '0',
    },
    requires => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    add_to_cleanup     => [ 'CLI-Coin-Toss-*' ],
);

$builder->create_build_script();
