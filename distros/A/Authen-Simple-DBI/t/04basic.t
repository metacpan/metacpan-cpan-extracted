#!perl

use strict;
use warnings;

use Test::More;

unless ( eval "use DBD::SQLite 1.0; 1;" ) {
    plan skip_all => 'needs DBD::SQLite >= 1.0 for testing';
}

plan tests => 10;

use_ok('Authen::Simple::DBI');

my $dbi = Authen::Simple::DBI->new(
    dsn       => 'dbi:SQLite:dbname=t/var/database.db',
    statement => 'SELECT password FROM users WHERE username = ?'
);

ok(   $dbi, 'Got instance' );
ok(   $dbi->authenticate( 'crypt',        'crypt'        ), 'Successfully authenticated using crypt() with Traditional DES' );
ok(   $dbi->authenticate( 'md5',          'md5'          ), 'Successfully authenticated using $1$' );
ok(   $dbi->authenticate( 'plain',        'plain'        ), 'Successfully authenticated using plain' );
ok(   $dbi->authenticate( 'sha',          'sha'          ), 'Successfully authenticated using {SHA}' );
ok(   $dbi->authenticate( 'smd5',         'smd5'         ), 'Successfully authenticated using {SMD5}' );
ok(   $dbi->authenticate( 'sha-1 hex',    'sha-1 hex'    ), 'Successfully authenticated using SHA-1 hex' );
ok(   $dbi->authenticate( 'sha-1 base64', 'sha-1 base64' ), 'Successfully authenticated using SHA-1 Base64' );
ok( ! $dbi->authenticate( 'bogus',        'bogus'        ), 'Failed to authenticate user bogus' );
