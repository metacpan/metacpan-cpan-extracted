#   -*- perl -*-

use strict;
use Test::More tests => 8;

use Data::Lazy;

{
    my $foo;
    my $c = 0;
    tie $foo, 'Data::Lazy', sub { "value".($c++) }, \$foo;

    ok(tied($foo), "Foo is tied");
    is($foo, "value0", "FETCH on LAZY_UNTIE");

 SKIP: {
	skip ("untie inside FETCH unsupported on 5.8.0 - upgrade "
	      ."to 5.8.1+", 1)
	    if $] < 5.008001 && $[ >= 5.008;
	is(tied($foo), undef, "Foo is now untied");
    }

    is($foo, "value0", "FETCH only called once");
}


{
    my $foo;
    my $c = 0;
    tie $foo, 'Data::Lazy', sub { "value".($c++) }, \$foo;

    ok(tied($foo), "Foo is tied");
    is($foo="bar", "bar", "STORE on LAZY_UNTIE");

 SKIP: {
	skip ("untie inside STORE unsupported on 5.8.0 - upgrade "
	      ."to 5.8.1+", 1)
	    if $] < 5.008001 && $[ >= 5.008;
	is(tied($foo), undef, "Foo is now untied");
    }

    is($foo, "bar", "STORE saved value");



}
