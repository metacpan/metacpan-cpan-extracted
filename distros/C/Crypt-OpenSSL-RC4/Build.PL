use 5.008001;
use strict;
use Module::Build 0.4004;
use Devel::CheckLib;

check_lib_or_exit(
    lib => [qw(crypto)]
);

my $build = Module::Build->new(
    module_name          => 'Crypt::OpenSSL::RC4',
    configure_requires       => {
        'Devel::CheckLib' => '0.99',
        'Module::Build'   => '0.4004',
    },
    test_requires       => {
        'Test::More' => '0.98',
    },
    requries             => {
        'XSLoader' => 0,
    },
    recommends           => {},
    recursive_test_files => 1,
    sign                 => 0,
    create_license       => 1,
    license              => 'perl',
    extra_linker_flags   => '-lcrypto',
    c_source             => './lib/Crypt/OpenSSL/',
    meta_merge => {
        resources => {
            repository => 'https://github.com/tokuhirom/Crypt-OpenSSL-RC4',
        },
    },
);
$build->create_build_script;

