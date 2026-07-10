#!/usr/bin/perl
use utf8;
use Test::More;
use Crypto::Utils::OpenSSL;

ok( __PACKAGE__->can('OPENSSL_free'), 'OPENSSL_free is exported' );

done_testing();
