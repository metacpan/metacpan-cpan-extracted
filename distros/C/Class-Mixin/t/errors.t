#!perl -T

use strict;
use warnings;
use Test::More tests => 3;

eval q{
package foo;
use Class::Mixin;
};
is( $@, '', "clean return w/no params" );

eval q{
package foo;
use Class::Mixin blah => 1;
};
like( $@, qr/^Must mixin 'to' or 'from' something /, "croak w/o to or from" );

ok( $INC{'Class/Mixin.pm'}, 'Class::Mixin still loaded' );

