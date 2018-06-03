use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CLI::LaTeX::Table',
    license             => 'gpl3',
    dist_author         => q{"Toshiyuki Shimono" <bin4tsv@gmail.com>},
    dist_version_from   => 'lib/CLI/LaTeX/Table.pm',
    release_status      => 'stable',
    script_files        => [qw[ scripts/transpose scripts/csel scripts/saikoro scripts/latextable scripts/csv2tsv] ],
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
    add_to_cleanup     => [ 'CLI-LaTeX-Table-*' ],
);

$builder->create_build_script();
