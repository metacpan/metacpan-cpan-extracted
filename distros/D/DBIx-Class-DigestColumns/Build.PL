use strict;
use Module::Build;

my %arguments = (
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => 'DBIx::Class::DigestColumns',
    requires           => {
        'DBIx::Class'               => 0.06002,
        'Digest::MD5'               => 0,
        'Digest'               		=> 1.11,
    },
    build_requires      => {
        'DBD::SQLite'               => 1.11,
    },
    recommends          => {
        'Digest::MD2'               => 0,
        'Digest::MD4'               => 0,
        'Digest::SHA'               => 0,
        'Digest::HMAC_MD5'          => 0,
        'Digest::HMAC_SHA1'         => 0,
        'Digest::CRC'         		=> 0,
        'Digest::Adler32'           => 0,
        'Digest::Whirlpool'         => 0,
        'Digest::Haval256'          => 0,
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    test_files         => [ glob('t/*.t')]
);

Module::Build->new(%arguments)->create_build_script;