use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CLI::Contingency::Table',
    license             => 'gpl3',
    dist_author         => q{"Toshiyuki Shimono" <bin4tsv@gmail.com>},
    dist_version_from   => 'lib/CLI/Contingency/Table.pm',
    release_status      => 'stable', # testing stable
    script_files        => [qw[ scripts/venn scripts/freq scripts/csel scripts/crosstable scripts/saikoro scripts/venn4]],
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
    add_to_cleanup     => [ 'CLI-Contingency-Table-*' ],
);

$builder->create_build_script();
