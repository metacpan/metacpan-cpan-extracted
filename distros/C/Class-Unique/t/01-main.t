#!perl -T

use Test::More tests => 12;
use Scalar::Util 'blessed';

BEGIN {
	use_ok( 'Class::Unique' );
}

package Class::Unique::Test;

use base 'Class::Unique';

sub foo { "foo" };
sub bar { "bar" };

package main;

my $obj1 = Class::Unique::Test->new;
my $obj2 = Class::Unique::Test->new;

isa_ok( $obj1, 'Class::Unique::Test' );
isa_ok( $obj2, 'Class::Unique::Test' );

isnt( blessed( $obj1 ), blessed( $obj2 ) );

ok( $obj1->foo eq 'foo' );
ok( $obj1->bar eq 'bar' );
ok( $obj2->foo eq 'foo' );
ok( $obj2->bar eq 'bar' );

$obj1->install( foo => sub { 'newfoo' } );

ok( $obj1->foo eq 'newfoo' );
ok( $obj1->bar eq 'bar' );
ok( $obj2->foo eq 'foo' );
ok( $obj2->bar eq 'bar' );
