use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Crypt::AES::CTR',
    license             => 'Perl_5',
    dist_author         => q{KnowZero},
    dist_version_from   => 'lib/Crypt/AES/CTR.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Encode'  => 0,
        'POSIX' => 0,
        'MIME::Base64' => 0,
        'Time::HiRes' => 0,
        'Math::BigInt' => 0,
    },
    add_to_cleanup     => [ 'Crypt-AES-CTR-*' ],
    create_readme => 1,
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
