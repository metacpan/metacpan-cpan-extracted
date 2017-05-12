use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Chart::EPS_graph',
    license             => 'perl',
    dist_author         => 'Ĝan Ŭesli Starling <gan@starling.us>',
    dist_version_from   => 'lib/Chart/EPS_graph.pm',
    requires => {
        'perl'          => '5.6.1',
        'Test::More'    => '0',
        'Cwd'           => '0',
        'Carp'          => '0',
        'Config'        => '0',
        'File::Find'    => '1.01',
    },
    add_to_cleanup      => [ 'Chart-EPS_graph-*' ],
);

$builder->create_build_script();
