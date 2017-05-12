use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Backticks',
    license             => 'perl',
    dist_author         => q{Anthony Kilna <anthony@kilna.com>},
    dist_version_from   => 'lib/Backticks.pm',
    build_requires      => { 'Test::More' => 0 },
    configure_requires  => { 'Module::Build' => 0.40 },
    requires => {
        'perl'           => 5.006,
        'Class::ISA'     => 0,
        'Filter::Simple' => 0,
        'Scalar::Util'   => 0,
    },
    add_to_cleanup      => [ 'Backticks-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
