#!/usr/bin/perl

use strict;

use Test::More tests => 19;
use Test::Exception;

use Crypt::NSS config_dir => "db";
use Crypt::NSS::Constants qw(:ssl);

# option defaults
my $status = 1;
lives_ok {
    $status = Crypt::NSS::SSL->get_option(SSL_NO_CACHE);
};
ok(!$status, "SSL_NO_CACHE is off by default");

lives_ok {
    Crypt::NSS::SSL->set_option(SSL_NO_CACHE, 1);
};

$status = Crypt::NSS::SSL->get_option(SSL_NO_CACHE);
ok($status, "SSL_NO_CACHE now on by default");

throws_ok {
    Crypt::NSS::SSL->set_option(-1, 0);
} qr/Failed to set option default: -?\d+/;

# Ciphers
ok(@{Crypt::NSS::SSL->_get_implemented_cipher_ids()});

$status = 0;
lives_ok {
    $status = Crypt::NSS::SSL->get_cipher(SSL_EN_RC4_128_WITH_MD5);
};
ok($status, "SSL_EN_RC4_128_WITH_MD5 is enabled by default");

lives_ok {
    Crypt::NSS::SSL->set_cipher(SSL_RSA_WITH_NULL_MD5, 1);
};
ok(Crypt::NSS::SSL->get_cipher(SSL_RSA_WITH_NULL_MD5), "SSL_RSA_WITH_NULL_MD5 now on by default");

lives_ok {
    Crypt::NSS::SSL->set_cipher(SSL_RSA_WITH_NULL_MD5, 0);
};
ok(!Crypt::NSS::SSL->get_cipher(SSL_RSA_WITH_NULL_MD5), "SSL_RSA_WITH_NULL_MD5 now off by default");

throws_ok {
    Crypt::NSS::SSL->set_cipher(-1000, 0);
} qr/Failed to set cipher default: -?\d+/;

# Cipher policies
for(qw(US France International)) {
    lives_ok {
        Crypt::NSS::SSL->set_cipher_suite($_);
    };
}
throws_ok {
    Crypt::NSS::SSL->set_cipher_suite("mtnpfy");
} qr/No cipher suite for 'mtnpfy' exists/;

# Session cache
lives_ok { 
    Crypt::NSS::SSL->config_server_session_cache({
        maxCacheEntries => 10_000,
        ssl2_timeout    => 100,
        ssl3_timeout    => 86400,
        shared          => 0,
    });
};

lives_ok { Crypt::NSS::SSL->clear_session_cache(); };
