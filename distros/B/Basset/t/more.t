use Test::More tests => 2;
use Basset::Test::More;
package Basset::Test::More;
{		Test::More::ok(1, "uses strict");
		Test::More::ok(1, "uses warnings");
};
