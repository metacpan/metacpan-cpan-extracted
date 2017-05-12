use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::TreeDraw',
    license             => 'perl',
    dist_author         => 'Daniel S. T. Hughes <dsth@cantab.net>',
    dist_version_from   => 'lib/Data/TreeDraw.pm',
    requires => {
        'Test::More'            => 0,
        'version'               => 0,
        'Scalar::Util'          => "1.22", 
        'Class::MOP'            => "0.95",
        'Text::SimpleTable'     => "2.0",
        'Carp'                  => "1.08",
        'MRO::Compat'   => '0',
    },
    add_to_cleanup      => [ 'Data-TreeDraw-*' ],
);

$builder->create_build_script();
