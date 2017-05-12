#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 21;

BEGIN {
    unshift @INC => ( 't/test_lib', '/test_lib' );
}

{

    package TestIt;

    use Class::Trait qw/RenameDoesToPerforms/;

    sub new { bless {}, shift }

    package TestItChild;

    our @ISA = 'TestIt';
}

can_ok 'TestIt', 'new';
ok my $test = TestIt->new, '... and calling it should succeed';
isa_ok $test, 'TestIt', '... and the object it returns';

can_ok $test, 'reverse';
is $test->reverse('this'), 'siht', '... and methods should work correctly';

can_ok $test, 'performs';
ok $test->performs('RenameDoesToPerforms'),
  '... and it should return true for traits it can do';
ok !$test->performs('NoSuchTrait'),
  '... and it should return false for traits it cannot do';

ok !$test->can('does'), '... and it should not have a "does()" method';
ok !$test->can('is'),   '... or an "is()" method';

can_ok 'TestItChild', 'new';
ok my $child = TestItChild->new, '... and calling it should succeed';
isa_ok $child, 'TestItChild', '... and the object it returns';
isa_ok $child, 'TestIt', '... and the object it returns';

can_ok $child, 'reverse';
is $child->reverse('this'), 'siht', '... and methods should work correctly';

can_ok $child, 'performs';
ok $child->performs('RenameDoesToPerforms'),
  '... and it should return true for traits it can do';
ok !$child->performs('NoSuchTrait'),
  '... and it should return false for traits it cannot do';

ok !$child->can('does'), '... and it should not have a "does()" method';
ok !$child->can('is'),   '... or an "is()" method';
