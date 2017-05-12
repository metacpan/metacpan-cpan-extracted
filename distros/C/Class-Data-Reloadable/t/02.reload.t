#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan'; # tests => 15;
use Test::Exception;

use Symbol 'delete_package';
use UNIVERSAL::require;

use lib 't';

$| = 1;

use MyTestClass;
use MyOtherTestClass;

MyTestClass->foo( 'fooval' );
MyOtherTestClass->foo( 'barval' );

# make accessors from outside
MyTestClass->mk_classdata( faff => 'feep' );
MyOtherTestClass->mk_classdata( 'foof' );
MyOtherTestClass->foof( 'woof' );

like( MyTestClass->faff, qr(^feep$) );
like( MyOtherTestClass->foof, qr(^woof$) );

like( MyTestClass->foo, qr(^fooval$), 'retrieved val' );
like( MyOtherTestClass->foo, qr(^barval$), 'retrieved other val from subclass' );


#use YAML;
#warn Dump( $Class::Data::Reloadable::ClassData );

delete_package( 'MyTestClass' );
delete_package( 'MyOtherTestClass' );

reload( 'MyTestClass' );
reload( 'MyOtherTestClass' );

# these are rebuilt when the packages are reloaded, because the mk_classdata
# calls are in the packages themselves
ok( MyTestClass->can( 'foo' ) );
ok( MyOtherTestClass->can( 'foo' ) );

# these are not rebuild, because the mk_classdata calls came from an external
# package
ok( ! MyTestClass->can( 'faff' ), 'MyTestClass can faff' );
ok( ! MyOtherTestClass->can( 'faff' ), 'MyOtherTestClass can faff' );
ok( ! MyOtherTestClass->can( 'foof' ), 'MyOtherTestClass can foof' );

like( MyTestClass->foo, qr(^fooval$), 'retrieved val' );
like( MyOtherTestClass->foo, qr(^barval$), 'retrieved other val from subclass' );

like( MyTestClass->faff, qr(^feep$) );
like( MyOtherTestClass->foof, qr(^woof$) );

# the methods get rebuilt in AUTOLOAD, if appropriate
ok( MyTestClass->can( 'faff' ), 'MyTestClass can faff' );
ok( MyOtherTestClass->can( 'faff' ), 'MyOtherTestClass can faff' );
ok( MyOtherTestClass->can( 'foof' ), 'MyOtherTestClass can foof' );

# don't build accessors for attributes we haven't seen before
dies_ok { MyTestClass->flurp } 'no flurping';

sub reload {
    my ( $module ) = @_;

    $module =~s~::~/~g;
    $module .= '.pm';

    delete $INC{$module};
    require $module;
}

