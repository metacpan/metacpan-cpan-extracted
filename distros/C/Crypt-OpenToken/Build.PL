use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name => 'Crypt::OpenToken',
    dist_author => 'Graham TerMarsch (cpan@howlingfrog.com)',
    license     => 'artistic_2',
    requires    => {
        'MIME::Base64'      => 0,
        'Digest::HMAC_SHA1' => 0,
        'Digest::SHA1'      => 0,
        'Crypt::Rijndael'   => 0,
        'Moose'             => 0,
        'DateTime'          => 0,
        'Date::Parse'       => 0,
        'Compress::Zlib'    => 0,
    },
    recommends => {
        'Crypt::CBC'      => 0,
        'Crypt::DES_EDE3' => 0,
        'Crypt::NULL'     => 0,
    },
    build_requires => {
        'Test::More'        => 0,
        'Test::Differences' => 0,
        'Test::Exception'   => 0,
    },
)->create_build_script();
