#! perl

use strict;
use warnings;
use Test::More tests => 5;

use Data::Struct;

# Define a struct.
struct Foo => qw(foo bar);

# Use the struct.
my $s = struct "Foo";

ok( !defined $s->foo, "s1: foo undef" );
ok( !defined $s->bar, "s1: bar undef" );

$s = struct Foo => { foo => 2 };

is ( $s->foo, 2, "s2: foo == 2" );
ok( !defined $s->bar, "s2: bar undef" );
$s->bar = 5;
is( $s->bar, 5, "s2: bar is 5" );
