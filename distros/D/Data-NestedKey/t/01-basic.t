use strict;
use warnings;

use Test::More;
use Data::NestedKey;
use Data::Dumper;

# Create a new object
my $nk = Data::NestedKey->new(
  'foo.bar.baz' => 42,
  'foo.bar.qux' => 'hello'
);

# Test getting values
is( $nk->get('foo.bar.baz'), 42,      'Get: foo.bar.baz = 42' );
is( $nk->get('foo.bar.qux'), 'hello', 'Get: foo.bar.qux = hello' );

# Test setting new values
$nk->set( 'foo.new.key' => 'world' );
is( $nk->get('foo.new.key'), 'world', 'Set: foo.new.key = world' );

# Test deleting a key
$nk->delete('foo.bar.baz');
ok( !$nk->exists_key('foo.bar.baz'), 'Deleted: foo.bar.baz' )
  or diag( Dumper( [ nk => $nk ] ) );

# Test `as_string()` outputs valid JSON
like( $nk->as_string(), qr/[{].*"foo".*[}]/xsm, 'as_string() produces valid JSON' );

done_testing();

1;
