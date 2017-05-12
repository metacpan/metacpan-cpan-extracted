#!/usr/bin/perl

use Test;
BEGIN { plan tests => 33 }

use DBIx::SQLEngine::Utility::CloneWithParams;
ok( 1 );

########################################################################

ok( clone_with_parameters(1), 1 );

########################################################################

$array = clone_with_parameters([ 1, 2, 3]);
ok( ref $array, 'ARRAY' );
ok( $array->[0] == 1 and $array->[1] == 2 and $array->[2] == 3 );

$hash = clone_with_parameters({ foo => 'FooBar', baz => 'Basil' });
ok( ref $hash, 'HASH' );
ok( $hash->{foo} eq 'FooBar' and $hash->{baz} eq 'Basil' );

########################################################################

ok( clone_with_parameters(\$1, 1), 1 );

ok( clone_with_parameters(\$1, 2), 2 );

########################################################################

# Check for parameter-count-mismatch exceptions
ok( eval { clone_with_parameters(\$1, 1); 1 } );
ok( ! eval { clone_with_parameters(\$1); 1 } );
ok( ! eval { clone_with_parameters(\$1, 1, 2, 3); 1 } );

########################################################################

$string = clone_with_parameters( \$1 . \$2, 'foo', 'bar');
ok( $string eq 'foobar' );

$string = clone_with_parameters( \$1 . "-" . \$2, 'foo', 'bar');
ok( $string eq 'foo-bar' );

########################################################################

$array = clone_with_parameters([ \$1, \$2, \$3], 3, 2, 1);
ok( ref $array, 'ARRAY' );
ok( $array->[0] == 3 and $array->[1] == 2 and $array->[2] == 1 );

$array = clone_with_parameters([ 1, \$1, 3], 2);
ok( ref $array, 'ARRAY' );
ok( $array->[0] == 1 and $array->[1] == 2 and $array->[2] == 3 );

$hash = clone_with_parameters({ foo => \$1, baz => \$2 }, 'FooBar', 'Basil');
ok( ref $hash, 'HASH' );
ok( $hash->{foo} eq 'FooBar' and $hash->{baz} eq 'Basil' );

########################################################################

$hash = clone_with_parameters({ \$1, \$2 }, 'FooBar', 'Basil');
ok( ref $hash, 'HASH' );
ok( $hash->{FooBar} eq 'Basil' );

########################################################################

$hash = clone_with_parameters({ foo => \$1, baz => [ \$2, \$2 ] }, 'FooBar', 'Basil');
ok( ref $hash, 'HASH' );
ok( $hash->{foo} eq 'FooBar' and $hash->{baz}[1] eq 'Basil' );

$hash = clone_with_parameters({ foo => \$2, baz => \$2 }, 'FooBar', 'Basil');
ok( ref $hash, 'HASH' );
ok( $hash->{foo} eq 'Basil' and $hash->{baz} eq 'Basil' );

########################################################################

# Clone objects
package My::SimpleObject;
sub new { my $class = shift; bless { @_ }, $class }
sub foo { ( @_ == 1 ) ? $_[0]->{foo} : ( $_[0]->{foo} = $_[1] ) }
sub bar { ( @_ == 1 ) ? $_[0]->{bar} : ( $_[0]->{bar} = $_[1] ) }

package main;

my $object = My::SimpleObject->new(
  foo => \$1, bar => \$2
); 
my $clone = clone_with_parameters( $object, 'Foozle', 'Basil' );
ok( ref($clone) );
ok( UNIVERSAL::isa($clone, 'My::SimpleObject') );
ok( $clone->foo,'Foozle' );
ok( $clone->bar, 'Basil' );

########################################################################

ok( clone_with_parameters(\&My::SimpleObject::foo), \&My::SimpleObject::foo );

{ 
  my $clone = clone_with_parameters(\"foo");
  ok( ref( $clone ) eq 'SCALAR' and $$clone eq 'foo' );
}

{ 
  my $clone = clone_with_parameters(\\"foo");
  ok( ref( $$clone ) eq 'SCALAR' and $$$clone eq 'foo' );
}

{ 
  my $foo = [];
  $foo->[0] = [ $foo ];
  my $clone = clone_with_parameters($foo);
  ok( ref( $clone ) eq 'ARRAY' and ref( $clone->[0] ) eq 'ARRAY' and ref( $clone->[0]->[0] ) eq 'ARRAY' );
}

########################################################################

1;
