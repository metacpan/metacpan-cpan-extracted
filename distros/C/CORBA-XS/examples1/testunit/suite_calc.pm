use strict;

package suite_calc;

use test_add;
use test_sub;
use test_mul;
use test_div;


sub suite {
	my $class = shift;

	my $suite = Test::Unit::TestSuite->empty_new("Calc Suite Tests");
	$suite->add_test(Test::Unit::TestSuite->new("test_add"));
	$suite->add_test(Test::Unit::TestSuite->new("test_sub"));
	$suite->add_test(Test::Unit::TestSuite->new("test_mul"));
	$suite->add_test(Test::Unit::TestSuite->new("test_div"));
	return $suite;
}

1;
