% my $class = shift;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => '<%= $class %>',
    license             => 'perl',
    dist_abstract       => "<%= $class %> server",
    dist_version_from   => 'lib/<%= $class %>.pm',
    build_requires => {
        'Test::More'          => 0,
        'Test::Script'        => 0,
        'Clustericious'       => '<%= Clustericious->VERSION || 1.08 %>',
    },
    add_to_cleanup      => [ '<%= $class %>-*' ],
);

$builder->create_build_script();

1;
