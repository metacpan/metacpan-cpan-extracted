use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Config::Param',
    license             => 'perl',
    dist_author         => q{Thomas Orgis <thomas@orgis.org>},
    dist_version_from   => 'lib/Config/Param.pm',
    build_requires => {
        'Test::More' => 0,
        'Storable' => 0,
        'File::Spec' => 0
    },
    requires => {
        'perl' => 5.008,
    },
    resources => {
        repository => {
             url => 'svn://scm.orgis.org/thor/param'
            ,web => 'http://scm.orgis.org/view/thor/param'
            ,type => 'svn'
        }
    },
    script_files => [ 'script/paramorama' ],
    add_to_cleanup      => [ 'Config-Param-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
