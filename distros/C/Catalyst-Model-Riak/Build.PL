use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    add_to_cleanup     => [qw/ Catalyst-Model-Riak-*
                               Catalyst-Helper-Model-Riak-* /],
    build_requires     => {
        'Test::More' => '0',
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    dist_version_from  => 'lib/Catalyst/Model/Riak.pm',
    license            => 'perl',
    module_name        => 'Catalyst::Model::Riak',
    requires           => {
        'Carp'            => '0',
        'Catalyst::Model' => '0',
        'Catalyst::Utils' => '0',
        'Net::Riak'		  => '0.16',
    },
);

$builder->create_build_script();
