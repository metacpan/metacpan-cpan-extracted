use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bio::RNA::Treekin',
    license             => 'gpl_3',
    dist_author         => q{Felix Kuehnl <xfelix@bioinf.uni-leipzig.de>},
    dist_version_from   => 'lib/Bio/RNA/Treekin.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More'            => 0,
        'Test::Exception'       => 0,
        'File::Spec::Functions' => 0,
        'File::Slurp'           => 0,
        'Digest::CRC'           => 0,
        'Test::NoWarnings'      => 0,
        'Scalar::Util'          => 0,
    },
    requires => {
        'Moose'                     => 2.2011,
        'MooseX::StrictConstructor' => 0.21,
        'namespace::autoclean'      => 0.28,
        'autodie'                   => 2.29,
        'Scalar::Util'              => 1.50,
        'List::Util'                => 1.50,
        'IO::Lines'                 => 2.111,
        'IPC::System::Simple'       => 1.25,
    },
    add_to_cleanup     => [ 'Bio-RNA-Treekin-*' ],
);

$builder->create_build_script();
