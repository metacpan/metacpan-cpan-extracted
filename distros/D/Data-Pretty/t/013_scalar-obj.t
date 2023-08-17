#!perl
use strict;
use warnings;
use lib './lib';
use vars qw( $DEBUG );
$DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
use Test::More;
plan tests => 3;

# print "1..3\n";

use Data::Pretty qw(dump); 
local $Data::Pretty::DEBUG = $DEBUG;

$a = 42;
bless \$a, "Foo";
diag( "Checking ", overload::StrVal( \$a ), " (", ref( \$a ), ")" ) if( $DEBUG );

my $d = dump($a);

is( "$d", q(do {
    my $a = 42;
    bless \$a, "Foo";
    $a;
}), 'dump blessed' );

$d = dump(\$a);
is( "$d", q(bless(do{\\(my $o = 42)}, "Foo")) );

$d = dump(\\$a);
is( "$d", q(\\bless(do{\\(my $o = 42)}, "Foo")) );

