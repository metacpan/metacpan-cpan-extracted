% my $class = shift;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => '<%= $class %>::Client',
    license             => 'perl',
    dist_version_from   => 'lib/<%= $class %>/Client.pm',
    requires => {
        'Clustericious::Client' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ '<%= $class %>-Client-*' ],
);

$builder->create_build_script();
