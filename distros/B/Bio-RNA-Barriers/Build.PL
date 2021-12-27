use 5.012;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bio::RNA::Barriers',
    license             => 'gpl_3',
    dist_author         => q{Felix Kuehnl <felix@bioinf.uni-leipzig.de>},
    dist_version_from   => 'lib/Bio/RNA/Barriers.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More' => '0',
        'Test::NoWarnings'  => 1.04,
        'Test::Exception'   => 0.43,
        'File::Slurp'       => 9999.23,
    },
    requires => {
        'Moose'                     => 2.2011,
        'MooseX::StrictConstructor' => 0.21,
        'namespace::autoclean'      => 0.28,
        'autodie'                   => 2.29,
        'Scalar::Util'              => 1.50,
        'List::Util'                => 1.50,
        'List::MoreUtils'           => 0.428,
        'File::Spec'                => 3.75,
        'IPC::System::Simple'       => 1.25,
    },
    add_to_cleanup     => [ 'Bio-RNA-Barriers-*' ],
);

$builder->create_build_script();
