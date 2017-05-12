use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    add_to_cleanup     => [ 'Catalyst-Model-TextLinkAds-*',
                            'Catalyst-Helper-Model-TextLinkAds-*' ],
    build_requires     => {
        'Test::More' => 0,
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    dist_version_from  => 'lib/Catalyst/Model/TextLinkAds.pm',
    license            => 'perl',
    module_name        => 'Catalyst::Model::TextLinkAds',
    requires           => {
        'Carp'            => '0',
        'Catalyst::Model' => '0',
        'Catalyst::Utils' => '0',
        'Class::C3'       => '0',
        'TextLinkAds'     => '0',
    },
);

$builder->create_build_script();
