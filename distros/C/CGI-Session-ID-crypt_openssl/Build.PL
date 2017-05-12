use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Session::ID::crypt_openssl',
    license             => 'perl',
    dist_author         => q{Helmut Weber <helmut.weber@bitbetrieb.de>},
    dist_version_from   => 'lib/CGI/Session/ID/crypt_openssl.pm',
    build_requires => {
        'Test::More' => 0,
        'CGI::Session' => 4.00,
        'Crypt::OpenSSL::Random' => 0,
        'Digest::MD5' => 0,
    },
    add_to_cleanup      => [ 'CGI-Session-ID-crypt_openssl-*' ],
    create_makefile_pl  => 'traditional',
    create_readme       => 1,
    meta_merge => {
        resources => {
            repository => 'https://github.com/bitbetrieb/CGI-Session-ID-crypt_openssl'
        }
    },
);

$builder->create_build_script();
