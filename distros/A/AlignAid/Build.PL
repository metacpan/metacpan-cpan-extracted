use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'AlignAid',
    license             => 'perl',
    dist_author         => 'Dave Messina <dave-pause@davemessina.net>',
    dist_version_from   => 'lib/AlignAid.pm',
    requires => {
        'version'    => 0,
        'Bio::SeqIO' => 0,
    },
    recommends => {
        'PP'         => 0,
        'BPdeluxe'   => 1.0,
    },
    build_requires      => {
        'Test::More'    => 0,        
    },                      
    add_to_cleanup      => [ 'AlignAid-*' ],
    create_makefile_pl  => 'passthrough',
);

$builder->create_build_script();
