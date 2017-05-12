#!perl

use strict;
use warnings;

use Test::More;
use Fcntl;

unless ( eval "use SDBM_File; 1;" ) {
    plan skip_all => 'needs SDBM_File for testing';
}

plan tests => 14;

use_ok('Authen::Simple::DBM');

{    
    my $dbm = SDBM_File->TIEHASH( 'database.db', O_RDWR | O_CREAT | O_TRUNC, 0664 )
      or die q/Failed to create database 'database.db'. Reason: $!/;

    my %create = (
        'plain'        => 'plain',
        'crypt'        => 'lk9Mh5KHGjAaM',
        'md5'          => '$1$NRe32ijZ$THIS7aDH.e093oDOGD10M/',
        'smd5'         => '{SMD5}eVWRi45+VqS2Xw4bJPN+SrGfpVg=',
        'sha'          => '{SHA}2PRZAyDhNDqRW2OUFwZQqPNdaSY=',
        'sha-1 base64' => '4zJ0YGPiLDff9wRf61PVIsC5Nms',
        'sha-1 hex'    => 'fc1e1866232bfebfac8a8db8f0225a5166fa1a99',
        'empty'        => '',
        'empty2'       => ':group,group:comment',
        'with groups'  => "lk9Mh5KHGjAaM:user,admin:comment",        
        "with null\0"  => "lk9Mh5KHGjAaM\0"
    );
    
    while ( my ( $key, $value ) = each(%create) ) {
        $dbm->STORE( $key => $value );
    }
}

my $dbm = Authen::Simple::DBM->new(
    path => 'database.db'
);

ok(   $dbm, 'Got instance' );
ok(   $dbm->authenticate( 'crypt',        'crypt'        ), 'Successfully authenticated user crypt' );
ok(   $dbm->authenticate( 'md5',          'md5'          ), 'Successfully authenticated user md5' );
ok(   $dbm->authenticate( 'plain',        'plain'        ), 'Successfully authenticated user plain' );
ok(   $dbm->authenticate( 'sha',          'sha'          ), 'Successfully authenticated user sha' );
ok(   $dbm->authenticate( 'smd5',         'smd5'         ), 'Successfully authenticated user smd5' );
ok(   $dbm->authenticate( 'sha-1 hex',    'sha-1 hex'    ), 'Successfully authenticated user sha-1 hex' );
ok(   $dbm->authenticate( 'sha-1 base64', 'sha-1 base64' ), 'Successfully authenticated user sha-1 base64' );
ok(   $dbm->authenticate( 'with null',    'crypt'        ), 'Successfully authenticated user with null' );
ok(   $dbm->authenticate( 'with groups',  'crypt'        ), 'Successfully authenticated user with groups' );
ok( ! $dbm->authenticate( 'bogus',        'bogus'        ), 'Failed to authenticate user bogus' );
ok( ! $dbm->authenticate( 'empty',        'empty'        ), 'Failed to authenticate user empty' );
ok( ! $dbm->authenticate( 'empty2',       'empty'        ), 'Failed to authenticate user empty2' );

END {
    unlink 'database.db.dir';
    unlink 'database.db.pag';
}
