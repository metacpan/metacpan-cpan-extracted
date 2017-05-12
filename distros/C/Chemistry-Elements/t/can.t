#!/usr/bin/perl

use Test::More 'no_plan';

my $class = 'Chemistry::Elements';

use_ok( $class );
ok( defined &{"${class}::can"}, "$class defines its own can" );

my $object = $class->new( 'U' );
isa_ok( $object, $class );

# try something that should return true
ok( $object->can('Z'), 'Object can call the Z method' );

# try something that is a defined sub but should return false
ok( ! $object->can('get_Z'), 'Object can call the Z method' );

# try something that is not a defined sub (and should return false)
ok( ! $object->can('not_there'), 'Object can call the Z method' );

# try it as a class method, which should fail
ok( ! defined $class->can('Z'),    "Can't call Z as a class method" );
ok( ! defined $class->can('name'), "Can't call Z as a class method" );

# try is as a class method, when it should work
ok( $class->can('isa'), "Can call isa as a class method" );
ok( $class->can('can'), "Can call can as a class method" );
