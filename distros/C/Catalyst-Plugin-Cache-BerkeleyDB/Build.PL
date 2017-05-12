use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl  => 'passthrough',
    license             => 'perl',
    module_name         => 'Catalyst::Plugin::Cache::BerkeleyDB',
    requires            => {
        'Cache::BerkeleyDB'     => 0,
    },
    test_files   => [
        glob('t/*.t') 
    ],
    create_readme     => 1,
    dist_author       => 'David Kamholz <dkamholz@cpan.org>',
);

$build->create_build_script;
