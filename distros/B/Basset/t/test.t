use Test::More tests => 4;
use Basset::Test;
package Basset::Test;
{		Test::More::ok(1, "uses strict");
		Test::More::ok(1, "uses warnings");
};
{#line 41 NAMEOFTEST
 Test::More::ok('true value', "Testing for true value");
 Test::More::is(1, 1, "1 = 1");
 #etc.
};
