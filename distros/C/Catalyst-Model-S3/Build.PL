use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    add_to_cleanup     => [qw/ Catalyst-Model-S3-*
                               Catalyst-Helper-Model-S3-* /],
    build_requires     => {
        'Test::More' => '0',
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    dist_version_from  => 'lib/Catalyst/Model/S3.pm',
    license            => 'perl',
    module_name        => 'Catalyst::Model::S3',
    requires           => {
        'Carp'            => '0',
        'Catalyst::Model' => '0',
        'Catalyst::Utils' => '0',
        'Class::C3'       => '0',
        'Net::Amazon::S3' => '0.31',
    },
);

$builder->create_build_script();
