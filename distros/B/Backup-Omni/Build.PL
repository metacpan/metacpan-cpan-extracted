use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Backup::Omni',
    license             => 'perl',
    dist_author         => q{Kevin L. Esteb <kesteb\@wsipc.org>},
    dist_version_from   => 'lib/Backup/Omni.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'                       => 5.008008,
        'Badger'                     => 0.09,
        'DateTime'                   => 0.78,
        'Try::Tiny'                  => 0.11,
        'Params::Validate'           => 0.95,
        'DateTime::Format::Strptime' => 1.52,
    },
    add_to_cleanup      => [ 'Backup-Omni-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
