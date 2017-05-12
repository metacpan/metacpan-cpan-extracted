use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Authen::HTTP::Signature',
    license             => 'perl',
    dist_author         => q{Mark Allen <mrallen1@yahoo.com>},
    dist_version_from   => 'lib/Authen/HTTP/Signature.pm',
    build_requires => {
        'Test::More' => 0,
        'Test::Fatal' => 0,
    },
    requires => {
        'perl' => '5.010',
        'HTTP::Message' => '6.02',
        'HTTP::Date' => '6.00',
        'Digest::SHA' => '5.70',
        'Crypt::OpenSSL::RSA' => 0.28,
        'MIME::Base64' => '3.13',
        'Moo' => '0.009013',
    },
    add_to_cleanup      => [ 'Authen-HTTP-Signature-*' ],
    create_makefile_pl => 'traditional',
    meta_merge => {
        resources => {
            repository => 'https://github.com/mrallen1/Authen-HTTP-Signature',
        },
    },
    
);

$builder->create_build_script();
