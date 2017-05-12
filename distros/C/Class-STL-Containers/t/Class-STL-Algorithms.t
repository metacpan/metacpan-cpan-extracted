# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Class-STL-Containers.t'

#########################

#use Test::More tests => 6;
#BEGIN { use_ok('Class::STL::Containers') };
#BEGIN { use_ok('Class::STL::Algorithms') };
#BEGIN { use_ok('Class::STL::Utilities') };

use Test;
use stl; # qw(:containers :algorithms :utilities);
BEGIN { plan tests => 64 }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $l = stl::list(qw(first second third fourth fifth));
ok (stl::find_if($l->begin(), $l->end(), stl::bind1st(stl::equal_to(), 'fifth'))->p_element()->data(), 'fifth', 'find_if()');
my $i = stl::find_if($l->begin(), $l->end(), stl::bind1st(stl::equal_to(), 'third'));
ok ($i->p_element()->data(), 'third', 'find_if()');

ok (stl::count_if($l->begin(), $l->end(), stl::bind2nd(stl::matches(), '^f\w+h$')), "2", 'count_if()');

my $erx = $l->factory('^FI');
ok (stl::count_if($l->begin(), $l->end(), stl::bind2nd(stl::matches_ic(), $erx)), "2", 'regex()');

$l2 = stl::list();
stl::transform($l->begin(), $l->end(), $l2->begin(), stl::ptr_fun('lc'));
stl::transform($l->begin(), $l->end(), $l2->begin(), stl::ptr_fun('uc'));
stl::transform($l->begin(), $l->end(), $l2->begin(), stl::ptr_fun('lc'));
$l2 = stl::list();
stl::transform($l->begin(), $l->end(), $l2->begin(), stl::ptr_fun('uc')); # test repeated calls to ptr_fun()
ok (join(' ', map($_->data(), $l->to_array())), "first second third fourth fifth", 'transform_1()');
ok (join(' ', map($_->data(), $l2->to_array())), "FIRST SECOND THIRD FOURTH FIFTH", 'transform_1()');

$l2 = stl::list(1, 2, 3, 4, 5);
my $e2 = $l2->factory(2);
ok (stl::count_if($l2->begin(), $l2->end(), stl::bind2nd(stl::greater(), $e2)), "3", 'count_if() with bind2nd()');
ok (stl::count_if($l2->begin(), $l2->end(), stl::bind1st(stl::greater(), $e2)), "1", 'count_if() with bind1st()');
ok (stl::count_if($l2->begin(), $l2->end(), stl::bind2nd(stl::greater(), 2)), "3", 'count_if() with bind2nd()');

$l3 = stl::list();
stl::transform($l->begin(), $l->end(), $l2->begin(), $l3->begin(), stl::ptr_fun_binary('::mybfun'));
$l3 = stl::list();
stl::transform($l->begin(), $l->end(), $l2->begin(), $l3->begin(), stl::ptr_fun_binary('::mybfun'));
ok (join(' ', map($_->data(), $l->to_array())), "first second third fourth fifth", 'transform_2()');
ok (join(' ', map($_->data(), $l2->to_array())), "1 2 3 4 5", 'transform_2()');
ok (join(' ', map($_->data(), $l3->to_array())), "first-1 second-2 third-3 fourth-4 fifth-5", 'transform_2()');

my $e6 = $l->factory('sixth');
$l->push_front($e6);
ok (stl::find($l->begin(), $l->end(), $e6)->p_element()->data(), "sixth", 'find()');
stl::remove($l->begin(), $l->end(), $e6);
$l->push_back($e6);
ok (stl::find($l->begin(), $l->end(), $e6)->p_element()->data(), "sixth", 'find()');

stl::remove($l->begin(), $l->end(), $e6);
ok (join(' ', map($_->data(), $l->to_array())), "first second third fourth fifth", 'remove()');

$l->push_back($e6, $e6);
$l->push_front($e6, $e6);
ok (join(' ', map($_->data(), $l->to_array())), "sixth sixth first second third fourth fifth sixth sixth", 'push_back/front()');

ok (stl::count($l->begin(), $l->end(), $e6), "4", 'count()');

my $e7 = $l->factory('seventh');
stl::replace($l->begin(), $l->end(), $e6, $e7);
ok (join(' ', map($_->data(), $l->to_array())), "seventh seventh first second third fourth fifth seventh seventh", 'replace()');

stl::replace_if($l->begin(), $l->end(), stl::bind2nd(stl::equal_to(), $e7), $e6);
ok (join(' ', map($_->data(), $l->to_array())), "sixth sixth first second third fourth fifth sixth sixth", 'replace_if()');

$l2->clear();
stl::replace_copy($l->begin(), $l->end(), $l2->begin(), $e6, $e7);
ok (join(' ', map($_->data(), $l2->to_array())), "seventh seventh first second third fourth fifth seventh seventh", 'replace_copy()');

$l2->clear();
stl::replace_copy_if($l->begin(), $l->end(), $l2->begin(), stl::bind1st(stl::equal_to(), $e6), $e7);
ok (join(' ', map($_->data(), $l2->to_array())), "seventh seventh first second third fourth fifth seventh seventh", 'replace_copy_if()');

$l2->clear();
stl::remove_copy($l->begin(), $l->end(), $l2->begin(), $e6);
ok (join(' ', map($_->data(), $l2->to_array())), "first second third fourth fifth", 'remove_copy()');

$l2->clear();
stl::remove_copy_if($l->begin(), $l->end(), $l2->begin(), stl::bind1st(stl::equal_to(), $e6));
ok (join(' ', map($_->data(), $l2->to_array())), "first second third fourth fifth", 'remove_copy_if()');

$l2->clear();
stl::copy_backward($l->begin(), $l->end(), $l2->begin());
ok (join(' ', map($_->data(), $l2->to_array())), "sixth sixth fifth fourth third second first sixth sixth", 'copy_backward()');

ok (stl::find($l2->begin(), $l2->end(), $e6)->p_element()->data(), 'sixth', 'find()');

$l2->clear();
stl::copy($l->begin(), $l->end(), $l2->begin());
ok (join(' ', map($_->data(), $l2->to_array())), "sixth sixth first second third fourth fifth sixth sixth", 'copy()');
ok (join(' ', map($_->data(), $l->to_array())), "sixth sixth first second third fourth fifth sixth sixth", 'copy()');

stl::remove_if($l2->begin(), $l2->end(),stl::bind2nd(stl::matches(), '^fi'));
ok (join(' ', map($_->data(), $l2->to_array())), "sixth sixth second third fourth sixth sixth", 'remove_if()');

sub mybfun { return $_[0] . '-' . $_[1]; }

$l2 = stl::list(qw( 1 2 3 4 ));
ok (join(' ', map($_->data(), $l2->to_array())), "1 2 3 4", 'generator()');

stl::generate($l2->begin(), $l2->end(), MyGenerator->new());
ok (join(' ', map($_->data(), $l2->to_array())), "2 4 8 16", 'generator()');

stl::generate_n($l2->begin(), 3, MyGenerator->new(counter => 4));
ok (join(' ', map($_->data(), $l2->to_array())), "8 16 32 16", 'generator_n()');

stl::fill($l2->begin(), $l2->end(), 99);
ok (join(' ', map($_->data(), $l2->to_array())), "99 99 99 99", 'fill()');

stl::fill_n($l2->begin(), 1, 9);
ok (join(' ', map($_->data(), $l2->to_array())), "9 99 99 99", 'fill_n()');

my $l4 = stl::list($l2);
ok (stl::equal($l2->begin(), $l2->end(), $l4->begin()), "1", 'equal()');
ok (join(' ', map($_->data(), $l4->to_array())), "9 99 99 99", 'copy');
ok (stl::equal($l2->begin(), $l2->end(), $l4->begin(), MyBinFun->new()), "1", 'equal(...binary_op)');

stl::fill($l4->begin(), $l4->begin(), 0);
ok (stl::equal($l2->begin(), $l2->end(), $l4->begin()), "0", '!equal()');
ok (stl::equal($l2->begin(), $l2->end(), $l4->begin(), MyBinFun->new()), "0", '!equal(...binary_op)');

stl::fill_n($l2->begin(), 1, 0);
ok (stl::equal($l2->begin(), $l2->end(), $l4->begin()), "1", 'equal()');

$l4 = stl::list(qw(1 2 3 4 5 6 7));
$i = $l4->begin();
$i++;
$i++;
stl::reverse($i, $l4->end());
ok (join(' ', map($_->data(), $l4->to_array())), "1 2 7 6 5 4 3", 'reverse()');

stl::reverse($l4->begin(), $i);
ok (join(' ', map($_->data(), $l4->to_array())), "7 2 1 6 5 4 3", 'reverse()');

$l2->clear();
stl::reverse_copy($l4->begin(), $l4->end(), $l2->begin());
ok (join(' ', map($_->data(), $l2->to_array())), "3 4 5 6 1 2 7", 'reverse_copy()');

$l2->clear();
$i = $l4->end();
--$i;
--$i;
stl::reverse_copy($l4->begin(), $i, $l2->begin());
ok (join(' ', map($_->data(), $l2->to_array())), "5 6 1 2 7", 'reverse_copy()');

$i = $l2->begin();
++$i;
++$i;
stl::rotate($l2->begin(), $i, $l2->end());
ok (join(' ', map($_->data(), $l2->to_array())), "1 2 7 5 6", 'rotate()');

$l2->clear();
$l4 = stl::list(qw(1 2 3 4 5 6 7));
$i = $l4->begin();
$i++;
$i++;
stl::rotate_copy($l4->begin(), $i, $l4->end(), $l2->begin());
ok (join(' ', map($_->data(), $l2->to_array())), "3 4 5 6 7 1 2", 'rotate_copy()');

stl::stable_partition($l2->begin(), $l2->end(), is_even->new());
ok (join(' ', map($_->data(), $l2->to_array())), "4 6 2 3 5 7 1", 'stable_partition()');

ok (stl::min_element($l2->begin(), $l2->end())->p_element()->data(), "1", 'min_element() -- 1');
ok (stl::min_element($l2->begin(), $l2->end(), stl::less())->p_element()->data(), "1", 'min_element() -- 2');

ok (stl::max_element($l2->begin(), $l2->end())->p_element()->data(), "7", 'max_element() -- 1');
ok (stl::max_element($l2->begin(), $l2->end(), stl::less())->p_element()->data(), "7", 'max_element() -- 2');

$l2 = stl::list(qw(4 5 5 9 -1 -1 -1 3 7 5 5 5 6 7 7 7 4 2 1 1));
stl::unique($l2->begin(), $l2->end());
ok (join(' ', map($_->data(), $l2->to_array())), "4 5 9 -1 3 7 5 6 7 4 2 1", 'unique() -- 1');

$l2 = stl::list(qw(4 5 5 9 -1 -1 -1 3 7 5 5 5 6 7 7 7 4 2 1 1));
stl::unique($l2->begin(), $l2->end(), stl::equal_to());
ok (join(' ', map($_->data(), $l2->to_array())), "4 5 9 -1 3 7 5 6 7 4 2 1", 'unique() -- 2');
stl::unique($l2->begin(), $l2->end(), stl::equal_to());
ok (join(' ', map($_->data(), $l2->to_array())), "4 5 9 -1 3 7 5 6 7 4 2 1", 'unique() -- 2');

$l2 = stl::list(qw(4 5 5 9 -1 -1 -1 3 7 5 5 5 6 7 7 7 4 2 1 1));
$l3->clear();
stl::unique_copy($l2->begin(), $l2->end(), $l3->begin());
ok (join(' ', map($_->data(), $l3->to_array())), "4 5 9 -1 3 7 5 6 7 4 2 1", 'unique_copy() -- 1');

$l3->clear();
stl::unique_copy($l2->begin(), $l2->end(), $l3->begin(), stl::equal_to());
ok (join(' ', map($_->data(), $l3->to_array())), "4 5 9 -1 3 7 5 6 7 4 2 1", 'unique_copy() -- 2');

ok (stl::adjacent_find($l2->begin(), $l2->end())->arr_idx(), "1", 'adjacent_find() -- 1');
ok (stl::adjacent_find($l2->begin(), $l2->end(), stl::equal_to())->arr_idx(), "1", 'adjacent_find() -- 2');

$l3 = stl::list(qw(4 5 5 9 -1 -1 -1 3 7 5 5 5 6 7 7 7 4 2 1 1));
stl::_sort($l3->begin(), $l3->end());
ok ($l3->join(' '), "-1 -1 -1 1 1 2 3 4 4 5 5 5 5 5 6 7 7 7 7 9", 'sort() -- 1');

$l3 = stl::list(qw(4 5 5 9 -1 -1 -1 3 7 5 5 5 6 7 7 7 4 2 1 1));
stl::stable_sort($l3->begin(), $l3->end(), stl::compare());
ok ($l3->join(' '), "-1 -1 -1 1 1 2 3 4 4 5 5 5 5 5 6 7 7 7 7 9", 'stable_sort() -- 2');

$l3 = stl::list(qw(1 2 3 4 5 6 7 8 9 10));
ok (stl::accumulate($l3->begin(), $l3->end(), 0)->data(), "55", 'accumulate() -- 1');
ok (stl::accumulate($l3->begin(), $l3->end(), 1, stl::multiplies())->data(), "3628800", 'accumulate() -- 2');
ok (stl::accumulate($l3->begin()+1, $l3->end()-1, 0)->data(), "44", 'accumulate() -- 1');

$l3 = stl::list(qw(4 5 5 9 -1 -1 -1 3 7 5 5 5 6 7 7 7 4 2 1 1));
stl::qsort($l3->begin(), $l3->end());
ok ($l3->join(' '), "-1 -1 -1 1 1 2 3 4 4 5 5 5 5 5 6 7 7 7 7 9", 'qsort() -- 1');

$l3 = stl::list(qw(4 5 5 9 -1 -1 -1 3 7 5 5 5 6 7 7 7 4 2 1 1));
stl::stable_qsort($l3->begin(), $l3->end(), stl::compare());
ok ($l3->join(' '), "-1 -1 -1 1 1 2 3 4 4 5 5 5 5 5 6 7 7 7 7 9", 'stable_qsort() -- 2');


{
  package is_even;
  use base qw(Class::STL::Utilities::FunctionObject::UnaryFunction);
  sub function_operator
  {
    my $self = shift;
    my $arg1 = shift;
    return $arg1->data() % 2 == 0;
  }
}
{
  package MyBinFun;
  use base qw(Class::STL::Utilities::FunctionObject::BinaryFunction);
  sub function_operator
  {
    my $self = shift;
    my $arg1 = shift;
    my $arg2 = shift;
    return $arg1->eq($arg2);
  }
}
  
{
  package MyGenerator;
  use base qw(Class::STL::Utilities::FunctionObject::Generator);
  use Class::STL::ClassMembers qw(counter);
  sub new
  {
    my $self = shift;
    my $class = ref($self) || $self;
    $self = $class->SUPER::new(@_);
    bless($self, $class);
    $self->members_init(counter => 1, @_);
    return $self;
  }
  sub function_operator
  {
    my $self = shift;
    $self->counter($self->counter() *2);
    return Class::STL::Element->new($self->counter());
  }
}
