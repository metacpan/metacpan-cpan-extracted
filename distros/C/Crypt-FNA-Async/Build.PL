use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Crypt::FNA::Async',
    license             => 'perl',
    dist_author         => q{Mario Rossano aka Anak <software@netlogicalab.com>},
    dist_abstract       => q{Crypt::FNA::Async allow parallel encryption/decryption with Crypt::FNA},
    dist_version_from   => 'lib/Crypt/FNA/Async.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => { 'Crypt::FNA' => '0.48' },
    add_to_cleanup      => [ 'Crypt-FNA-Async-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
