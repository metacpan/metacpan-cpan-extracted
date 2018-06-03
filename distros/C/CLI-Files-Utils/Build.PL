use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CLI::Files::Utils',
    license             => 'gpl3',
    dist_author         => q{"Toshiyuki Shimono" <bin4tsv@gmail.com>},
    dist_version_from   => 'lib/CLI/Files/Utils.pm',
    script_files        => [ qw[ scripts/madeafter scripts/dirhier scripts/colorplus scripts/init.sh] ] ,
    release_status      => 'stable',
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
    add_to_cleanup     => [ 'CLI-Files-Utils-*' ],
);

$builder->create_build_script();
