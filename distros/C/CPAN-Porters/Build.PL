use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CPAN::Porters',
    license             => 'perl',
    dist_abstract       => "Description on how to created binary packages from CPAN distributions",
    create_makefile_pl  => 'traditional',
    create_readme       => 1,
    requires            => {
    },
    build_requires      => {
        'Test::More'                => '0.47',
    },
);

$builder->create_build_script();
