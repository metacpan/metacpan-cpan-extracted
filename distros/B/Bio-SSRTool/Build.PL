use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bio::SSRTool',
    license             => 'gpl',
    dist_author         => q{Ken Youens-Clark <kclark@cpan.org>},
    dist_version_from   => 'lib/Bio/SSRTool.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
        'IO::Scalar' => 0,
    },
    build_requires => {
        'Module::Build' => 0.4003,
        'Test::Exports' => 0,
    },
    add_to_cleanup      => [ 'Bio-SSRTool-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
