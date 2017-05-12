# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Class-STL-Containers.t'

#########################

#use Test::More tests => 5;
#BEGIN { use_ok('Class::STL::Containers') };
#BEGIN { use_ok('Class::STL::Algorithms') };
#BEGIN { use_ok('Class::STL::Utilities') };

use Test;
use stl; # qw(:containers :algorithms :utilities :iterators);
BEGIN { plan tests => 60 }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $l = stl::list(qw(first second third fourth fifth));

stl::remove_if($l->begin(), $l->end(), stl::bind2nd(stl::matches(), '^fi'));
ok (join('', map($_->data(), $l->to_array())), "secondthirdfourth", 'matches()');

my $f = $l->factory('third');
stl::remove_if($l->begin(), $l->end(), stl::bind1st(stl::equal_to(), $f));
ok (join('', map($_->data(), $l->to_array())), "secondfourth", 'equal_to()');

{
	package MyClass;
	use base qw(Class::STL::Element);
}
my $e = MyClass->new(data => 100, data_type => 'numeric');
my $e2 = MyClass->new($e);
my $e3 = MyClass->new(data => 101, data_type => 'numeric');
ok (stl::equal_to()->function_operator($e, $e2), "1", "equal_to()");
ok (stl::equal_to()->function_operator($e, 100), "1", "equal_to()");
ok (stl::equal_to()->function_operator(100, $e), "1", "equal_to()");
ok (stl::equal_to()->function_operator(100, 100), "1", "equal_to()");

ok (stl::not_equal_to()->function_operator($e, $e2), "", "not_equal_to()");
ok (stl::not_equal_to()->function_operator($e, 100), "", "not_equal_to()");
ok (stl::not_equal_to()->function_operator(100, $e), "", "not_equal_to()");
ok (stl::not_equal_to()->function_operator(100, 100), "", "not_equal_to()");

ok (stl::not_equal_to()->function_operator($e, $e3), "1", "not_equal_to()");
ok (stl::not_equal_to()->function_operator($e, 101), "1", "not_equal_to()");
ok (stl::not_equal_to()->function_operator(101, $e), "1", "not_equal_to()");
ok (stl::not_equal_to()->function_operator(100, 101), "1", "not_equal_to()");

ok (stl::greater()->function_operator($e3, $e2), "1", "greater()"); # $e3 > $e2
ok (stl::greater()->function_operator($e3, 100), "1", "greater()"); # $e3 > $e2
ok (stl::greater()->function_operator(102, $e3), "1", "greater()"); # $e3 > $e2
ok (stl::greater()->function_operator(102, 101), "1", "greater()"); # $e3 > $e2

ok (stl::less()->function_operator($e2, $e3), "1", "less()"); # $e2 < $e3
ok (stl::less()->function_operator($e2, 101), "1", "less()"); # $e2 < $e3
ok (stl::less()->function_operator(100, $e3), "1", "less()"); # $e2 < $e3
ok (stl::less()->function_operator(100, 101), "1", "less()"); # $e2 < $e3

ok (stl::greater_equal()->function_operator($e3, $e2), "1", "greater_equal()");
ok (stl::greater_equal()->function_operator($e3, 101), "1", "greater_equal()");
ok (stl::greater_equal()->function_operator(100, $e2), "1", "greater_equal()");
ok (stl::greater_equal()->function_operator(101, 100), "1", "greater_equal()");

ok (stl::less_equal()->function_operator($e2, $e3), "1", "less_equal()");
ok (stl::less_equal()->function_operator($e2, 101), "1", "less_equal()");
ok (stl::less_equal()->function_operator(100, $e3), "1", "less_equal()");
ok (stl::less_equal()->function_operator(100, 101), "1", "less_equal()");

ok (stl::compare()->function_operator($e2, $e3), "-1", "compare()"); # $e2 < $e3
ok (stl::compare()->function_operator($e2, 101), "-1", "compare()"); # $e2 < $e3
ok (stl::compare()->function_operator(100, $e3), "-1", "compare()"); # $e2 < $e3
ok (stl::compare()->function_operator(100, 101), "-1", "compare()"); # $e2 < $e3

ok (stl::compare()->function_operator($e3, $e), "1", "compare()"); # $e3 > $e
ok (stl::compare()->function_operator($e3, 100), "1", "compare()"); # $e3 > $e
ok (stl::compare()->function_operator(101, $e), "1", "compare()"); # $e3 > $e
ok (stl::compare()->function_operator(101, 100), "1", "compare()"); # $e3 > $e

ok (stl::compare()->function_operator($e2, $e), "0", "compare()");
ok (stl::compare()->function_operator($e2, 100), "0", "compare()");
ok (stl::compare()->function_operator(100, $e), "0", "compare()");
ok (stl::compare()->function_operator(100, 100), "0", "compare()");

$l2 = stl::list(qw(1 2 3 4 5));
$e2 = $l2->factory(2);
ok (stl::count_if($l2->begin(), $l2->end(), stl::bind2nd(stl::greater(), $e2)), "3", 'bind2nd()');
ok (stl::count_if($l2->begin(), $l2->end(), stl::bind2nd(stl::greater(), 2)), "3", 'bind2nd()');
ok (stl::count_if($l2->begin(), $l2->end(), stl::bind1st(stl::greater(), $e2)), "1", 'bind1st()');
ok (stl::count_if($l2->begin(), $l2->end(), stl::bind2nd(stl::greater(), 2)), "3", 'bind2nd()');
ok (stl::count_if($l2->begin(), $l2->end(), stl::bind1st(stl::greater(), 2)), "1", 'bind1st()');

my $l3 = stl::list();
stl::transform($l2->begin(), $l2->end(), $l3->begin(), stl::bind2nd(stl::multiplies(), 2));
ok (join(' ', map($_->data(), $l3->to_array())), "2 4 6 8 10", 'multiplies()');

my $l4 = stl::list();
stl::transform($l3->begin(), $l3->end(), $l4->begin(), stl::bind2nd(stl::minus(), 1));
ok (join(' ', map($_->data(), $l4->to_array())), "1 3 5 7 9", 'minus()');

$l4->clear();
stl::transform($l3->begin(), $l3->end(), $l4->begin(), stl::bind2nd(stl::plus(), 1));
ok (join(' ', map($_->data(), $l4->to_array())), "3 5 7 9 11", 'plus()');

$l4->clear();
stl::transform($l3->begin(), $l3->end(), $l4->begin(), stl::bind2nd(stl::divides(), 2));
ok (join(' ', map($_->data(), $l4->to_array())), "1 2 3 4 5", 'divides()');

$l4->clear();
stl::transform($l3->begin(), $l3->end(), $l4->begin(), stl::bind2nd(stl::modulus(), 3));
ok (join(' ', map($_->data(), $l4->to_array())), "2 1 0 2 1", 'modulus()');

my $l5 = stl::list();
stl::transform($l3->begin(), $l3->end(), $l4->begin(), $l5->begin(), stl::logical_and());
ok (join(' ', map($_->data(), $l5->to_array())), "1 1 0 1 1", 'logical_and()');

$l5->clear();
stl::transform($l3->begin(), $l3->end(), $l4->begin(), $l5->begin(), stl::logical_or());
ok (join(' ', map($_->data(), $l5->to_array())), "1 1 1 1 1", 'logical_or()');

ok (stl::not2(stl::less())->function_operator(1, 4), '', 'not2');
ok (stl::not2(stl::less())->function_operator(4, 1), '1', 'not2');
ok (stl::not2(stl::greater())->function_operator(1, 4), '1', 'not2');
ok (stl::not2(stl::greater())->function_operator(4, 1), '', 'not2');

$l2 = stl::list(qw(1 2 3 4 5));
$l5->clear();
stl::transform($l2->begin(), $l2->end(), $l5->begin(), stl::negate());
ok (join(' ', map($_->data(), $l5->to_array())), "-1 -2 -3 -4 -5", 'negate()');

$l2->clear();
stl::transform($l5->begin(), $l5->end(), $l2->begin(), stl::negate());
ok ($l2->join(' '), "1 2 3 4 5", 'negate()');
