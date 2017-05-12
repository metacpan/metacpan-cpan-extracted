use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bio::NEXUS::Import',
    license             => 'perl',
    dist_author         => 'LIMAONE <limaone@cpan.org>',
    dist_version_from   => 'lib/Bio/NEXUS/Import.pm',
    requires => {
        'version'    => 0,
        'Bio::NEXUS' => 0.67,
        'perl'       => '5.6.1',
    },
    build_requires => {
        'Test::More' => 0,
    },    
    script_files        => [ 
                  'bin/phylip2nex.pl',
                           ],
    meta_merge => {
        resources => {
            repository => 'http://github.com/lima1/p5-bio-nexus-import',
        },
    },
    add_to_cleanup      => [ 'Bio-NEXUS-Import-*' ],
);

$builder->create_build_script();
