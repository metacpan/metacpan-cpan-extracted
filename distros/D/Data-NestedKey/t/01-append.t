use strict;
use warnings;

use Data::NestedKey;
use JSON;
use Test::More;

# Create a new object with an empty structure
my $nk = Data::NestedKey->new( {} );

# --- TEST: Setting a Scalar Value ---
$nk->set( 'foo.bar' => 1 );
is_deeply( $nk->get('foo.bar'), 1, 'Set scalar: foo.bar = 1' );

# --- TEST: Appending to Scalar (Convert to Array) ---
$nk->set( '+foo.bar' => 2 );
is_deeply( $nk->get('foo.bar'), [ 1, 2 ], 'Append: foo.bar -> [1, 2]' );

$nk->set( '+foo.bar' => 3 );
is_deeply( $nk->get('foo.bar'), [ 1, 2, 3 ], 'Append: foo.bar -> [1, 2, 3]' );

# --- TEST: Resetting Scalar ---
$nk->set( 'foo.bar' => 99 );
is_deeply( $nk->get('foo.bar'), 99, 'Reset: foo.bar = 99' );

# --- TEST: Appending After Reset ---
$nk->set( '+foo.bar' => 100 );
is_deeply( $nk->get('foo.bar'), [ 99, 100 ], 'Append after reset: foo.bar -> [99, 100]' );

# --- TEST: Appending to a New Hash Key ---
$nk->set( 'config' => { key1 => 'val1' } );
is_deeply( $nk->get('config'), { key1 => 'val1' }, 'Set hash: config' );

$nk->set( '+config' => { key2 => 'val2' } );
is_deeply( $nk->get('config'), { key1 => 'val1', key2 => 'val2' }, 'Append to hash: config' );

# --- TEST: Deleting a Scalar Key ---
$nk->set( 'delete_me'  => 'gone' );
$nk->set( '-delete_me' => 'gone' );
ok( !$nk->exists_key('delete_me'), 'Deleted scalar key: delete_me' );

# --- TEST: Deleting an Array Element ---
$nk->set( 'array_test'  => [ 1, 2, 3, 4 ] );
$nk->set( '-array_test' => 2 );
is_deeply( $nk->get('array_test'), [ 1, 3, 4 ], 'Deleted element from array: array_test' );

# --- TEST: Deleting a Hash Key ---
$nk->set( 'hash_test'  => { key1 => 'val1', key2 => 'val2' } );
$nk->set( '-hash_test' => 'key1' );
is_deeply( $nk->get('hash_test'), { key2 => 'val2' }, 'Deleted key from hash: hash_test' );

# --- TEST: JSON Output Consistency ---
$Data::NestedKey::FORMAT = 'JSON';
my $expected_json = {
  foo        => { bar  => [ 99, 100 ] },
  config     => { key1 => 'val1', key2 => 'val2' },
  array_test => [ 1, 3, 4 ],
  hash_test  => { key2 => 'val2' }
};
is_deeply( decode_json( $nk->as_string() ), $expected_json, 'JSON serialization matches expected structure' );

done_testing();
