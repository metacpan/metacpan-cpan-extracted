#!perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;

unless ( eval "use DBD::SQLite 1.0; 1;" ) {
    plan skip_all => 'needs DBD::SQLite >= 1.0 for testing';
}

plan tests => 11;

use_ok('Authen::Simple::CDBI');
use_ok('MyClass');

my $cdbi = Authen::Simple::CDBI->new(
    class    => 'MyClass',
    username => 'username',
    password => 'password'
);

ok(   $cdbi, 'Got instance' );
ok(   $cdbi->authenticate( 'crypt',        'crypt'        ), 'Successfully authenticated using crypt() with Traditional DES' );
ok(   $cdbi->authenticate( 'md5',          'md5'          ), 'Successfully authenticated using $1$' );
ok(   $cdbi->authenticate( 'plain',        'plain'        ), 'Successfully authenticated using plain' );
ok(   $cdbi->authenticate( 'sha',          'sha'          ), 'Successfully authenticated using {SHA}' );
ok(   $cdbi->authenticate( 'smd5',         'smd5'         ), 'Successfully authenticated using {SMD5}' );
ok(   $cdbi->authenticate( 'sha-1 hex',    'sha-1 hex'    ), 'Successfully authenticated using SHA-1 hex' );
ok(   $cdbi->authenticate( 'sha-1 base64', 'sha-1 base64' ), 'Successfully authenticated using SHA-1 Base64' );
ok( ! $cdbi->authenticate( 'bogus',        'bogus'        ), 'Failed to authenticate user bogus' );
