use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Algorithm::GoldenSection',
    license             => 'perl',
    dist_author         => 'Daniel S. T. Hughes <dsth@cantab.net>',
    dist_version_from   => 'lib/Algorithm/GoldenSection.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Carp'       => "1.08",
        'Readonly'   => "1.03",
    },
    add_to_cleanup      => [ 'Algorithm-GoldenSection-*' ],
);

$builder->create_build_script();
