use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bio::Tools::Primer3Redux',
    license             => 'perl',
    dist_author         => q{Chris Fields <cjfields@bioperl.org>},
    dist_version     => 0.09,
    build_requires => {
        'Test::Most'           => 0,
    },
    requires => {
        'Bio::Root::Version'   => '1.006.900',
    },
    recursive_test_files     => 1,
    add_to_cleanup      => [ 'Bio-Tools-Primer3Redux-*' ],
);

$builder->create_build_script();
