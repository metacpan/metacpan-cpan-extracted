# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Class-STL-Containers.t'

#########################

#use Test::More tests => 14;
#BEGIN { use_ok('Class::STL::Containers') };
#BEGIN { use_ok('Class::STL::Algorithms') };
#BEGIN { use_ok('Class::STL::Utilities') };
#BEGIN { use_ok('Class::STL::Iterators') };
#BEGIN { use_ok('Class::STL::Element') };

use Test;
use stl; # qw(:containers :algorithms :utilities :iterators);
BEGIN { plan tests => 34 }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $l = stl::list(qw(red blue green white yellow));

my $iter2 = $l->end();
$iter2 -= 2;
ok ($iter2->p_element()->data(), 'green', 'iterator->operator -=');

my $iter1;
for ($iter1 = $l->begin(); $iter1 != $iter2; ++$iter1) {}
ok ($iter1->p_element()->data(), 'green', 'iterator->operator !=');
for ($iter1 = $l->begin(); $iter1 < $iter2; ++$iter1) {}
ok ($iter1->p_element()->data(), 'green', 'iterator->operator <');
for ($iter1 = $l->begin(); $iter1 <= $iter2; ++$iter1) {}
ok ($iter1->p_element()->data(), 'white', 'iterator->operator <=');

$iter2 = $l->begin();
$iter2++;
for ($iter1 = $l->end(); $iter1 != $iter2; --$iter1) {}
ok ($iter1->p_element()->data(), 'blue', 'iterator->operator !=');
for ($iter1 = $l->end(); $iter1 > $iter2; --$iter1) {}
ok ($iter1->p_element()->data(), 'blue', 'iterator->operator >');
for ($iter1 = $l->end(); $iter1 >= $iter2; --$iter1) {}
ok ($iter1->p_element()->data(), 'red', 'iterator->operator >=');

my $i = $l->begin();
ok ($i->p_element()->data(), 'red', 'iterator->first()');
$i = $i->next();
ok ($i->p_element()->data(), 'blue', 'iterator->next()');
$i = $i->next();
ok ($i->p_element()->data(), 'green', 'iterator->next()');
$i = $i->prev();
ok ($i->p_element()->data(), 'blue', 'iterator->prev()');
$i = $i->last();
ok ($i->p_element()->data(), 'yellow', 'iterator->last()');

my @data;
for (my $oi = $l->begin(); !$oi->at_end(); $oi++) {
	push(@data, $oi->p_element()->data());
}
ok (join(' ', @data), "red blue green white yellow", "iterator->operator ++");

@data = ();
for (my $oi = $l->end(); !$oi->at_end(); --$oi) {
	push(@data, $oi->p_element()->data());
}
ok (join(' ', @data), "yellow white green blue red", "iterator->operator --");

@data = ();
for (my $oi = $l->rbegin(); !$oi->at_end(); ++$oi) {
	push(@data, $oi->p_element()->data());
}
ok (join(' ', @data), "yellow white green blue red", "reverse_iterator->operator ++");

@data = ();
for (my $oi = $l->rend(); !$oi->at_end(); $oi--) {
	push(@data, $oi->p_element()->data());
}
ok (join(' ', @data), "red blue green white yellow", "reverse_iterator->operator --");

my $ri = stl::reverse_iterator($l->rbegin());
ok ($ri->p_element()->data(), 'yellow', 'reverse_iterator->first()');
$ri->next();
ok ($ri->p_element()->data(), 'white', 'reverse_iterator->next()');
$ri->prev();
ok ($ri->p_element()->data(), 'yellow', 'reverse_iterator->prev()');
$ri->last();
ok ($ri->p_element()->data(), 'red', 'reverse_iterator->last()');

$ri = $l->begin();
$ri += 2;
ok ($ri->p_element()->data(), 'green', 'iterator->operator +=');

my $ri2 = stl::forward_iterator($ri);
ok ($ri2->p_element()->data(), 'green', 'forward_iterator');

ok (stl::distance($l->begin(), $ri2), '2', 'distance');
ok (stl::distance($l->begin(), $l->end()), $l->size()-1, 'distance');

ok (stl::advance($ri, 2)->p_element()->data(), 'yellow', 'advance(+)');

ok (stl::advance($ri, -2)->p_element()->data(), 'green', 'advance(-)');

my $l2 = stl::list(qw(1 2 3 4 5 6 7 8 9));
my $l3 = stl::list();
stl::copy($l2->begin()+3, $l2->end(), stl::back_inserter($l3));
ok (join(' ', map($_->data(), $l3->to_array())), "4 5 6 7 8 9", 'back_inserter()');

$l3->clear();
stl::copy_backward($l2->begin()+3, $l2->end(), stl::back_inserter($l3));
ok (join(' ', map($_->data(), $l3->to_array())), "9 8 7 6 5 4", 'back_inserter()');

$l3->clear();
stl::copy($l2->begin()+3, $l2->end(), stl::front_inserter($l3));
ok (join(' ', map($_->data(), $l3->to_array())), "9 8 7 6 5 4", 'front_inserter()');

$l3->clear();
stl::copy_backward($l2->begin()+3, $l2->end(), stl::front_inserter($l3));
ok (join(' ', map($_->data(), $l3->to_array())), "4 5 6 7 8 9", 'front_inserter()');

my $ins = stl::inserter($l3, $l3->begin()+2);
$ins->assign($l3->factory(qw(10)));
$ins->assign($l3->factory(qw(11)));
ok (join(' ', map($_->data(), $l3->to_array())), "4 5 10 11 6 7 8 9", 'inserter()');

stl::transform($l3->begin(), $l3->end(), stl::front_inserter($l2), stl::bind1st(stl::multiplies(), 2));
ok (join(' ', map($_->data(), $l2->to_array())), "18 16 14 12 22 20 10 8 1 2 3 4 5 6 7 8 9", 'front_inserter()');

my $ll1 = stl::list(qw(3 2 1));
my $ll2 = stl::list(qw(4 5 6));
my $ll3 = stl::list(qw(7 8 9));
my $ll4 = stl::list();
stl::copy($ll1->begin(), $ll1->end(), stl::front_inserter($ll4));
stl::copy($ll3->begin(), $ll3->end(), stl::back_inserter($ll4));
ok (join(' ', map($_->data(), $ll4->to_array())), "1 2 3 7 8 9", 'inserters');
my $iseven = stl::find($ll4->begin(), $ll4->end(), 7);
stl::copy($ll2->begin(), $ll2->end(), stl::inserter($ll4, $iseven));
ok (join(' ', map($_->data(), $ll4->to_array())), "1 2 3 4 5 6 7 8 9", 'inserters');
