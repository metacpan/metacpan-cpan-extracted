use strict;
use warnings;
use Test::More tests => 9;

BEGIN { use_ok 'Coat::Persistent::Meta' }

use lib './t';
use CoatPersistentA;
use CoatPersistentB;

is( Coat::Persistent::Meta->table_name('CoatPersistentA'), 
    'table_a', 
    'A is table_a' );

is( Coat::Persistent::Meta->table_name('CoatPersistentB'), 
    'table_b', 
    'B is table_b' );

ok( ! defined(Coat::Persistent::Meta->registry('User')), 
    'model User not defined' );

ok( Coat::Persistent::Meta->table_name(User => 'users' ),
    'table_name User -> users' );
is( 'users', Coat::Persistent::Meta->table_name('User'),
    'table_name == users');

ok( defined(Coat::Persistent::Meta->registry('User')), 
    'model User defined' );

ok( Coat::Persistent::Meta->primary_key(User => 'id'),
    'primary_key User -> id' );
is( 'id', Coat::Persistent::Meta->primary_key('User'),
    'primary_key == id');

