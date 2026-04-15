#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# Load Class.pm once at the beginning
require_ok('Class');

# Test 1: Basic single-file inheritance
{
    package Test::Basic::Parent;
    use Class;
    sub parent_method { "parent_value" }
    sub common_name   { "parent_common" }

    package Test::Basic::Child;
    use Class;
    extends 'Test::Basic::Parent';
    sub child_method { "child_value" }
}

my $basic_child = Test::Basic::Child->new;
ok($basic_child->isa('Test::Basic::Parent'), 'Basic inheritance: isa works');
is($basic_child->parent_method, 'parent_value', 'Basic inheritance: parent method works');
is($basic_child->child_method, 'child_value', 'Basic inheritance: child method works');
is($basic_child->common_name, 'parent_common', 'Basic inheritance: inherited common method works');

# Test 2: Method availability with can()
ok(Test::Basic::Child->can('parent_method'), 'Basic inheritance: can() finds parent method');
ok(Test::Basic::Child->can('child_method'), 'Basic inheritance: can() finds own method');
ok(Test::Basic::Child->can('common_name'), 'Basic inheritance: can() finds inherited method');

# Test 3: Multiple inheritance
{
    package Test::Multi::Parent1;
    use Class;
    sub parent1_method { "parent1" }

    package Test::Multi::Parent2;
    use Class;
    sub parent2_method { "parent2" }

    package Test::Multi::Child;
    use Class;
    extends qw/Test::Multi::Parent1 Test::Multi::Parent2/;
    sub child_method { "child" }
}

my $multi_child = Test::Multi::Child->new;
is($multi_child->parent1_method, 'parent1', 'Multiple inheritance: first parent method');
is($multi_child->parent2_method, 'parent2', 'Multiple inheritance: second parent method');
is($multi_child->child_method, 'child', 'Multiple inheritance: own method');

# Test 4: Method overriding
{
    package Test::Override::Parent;
    use Class;
    sub method { "parent" }

    package Test::Override::Child;
    use Class;
    extends 'Test::Override::Parent';
    sub method { "child_override" }
}

my $override_child = Test::Override::Child->new;
is($override_child->method, 'child_override', 'Method overriding: child method takes precedence');

# Test 5: Verify methods are actually copied (not just inherited via ISA)
{
    no strict 'refs';
    ok(defined &Test::Basic::Child::parent_method,
       'Method copying: parent method exists in child symbol table');
    ok(defined &Test::Basic::Child::common_name,
       'Method copying: inherited method exists in child symbol table');
}

# Test 6: Special methods are NOT copied
{
    package Test::Special::Parent;
    use Class;
    sub BUILD { }
    sub _private { "private" }

    package Test::Special::Child;
    use Class;
    extends 'Test::Special::Parent';
}

{
    no strict 'refs';
    ok(!defined &Test::Special::Child::BUILD,
       'Special methods: BUILD not copied to child');
    ok(!defined &Test::Special::Child::_private,
       'Special methods: private methods (starting with _) not copied');
}

# Test 7: Your specific Shape case reproduction
{
    package Test::Shape::Base;
    use Class;
    sub id   { shift->{id}   }
    sub type { shift->{type} }

    package Test::Shape::Circle;
    use Class;
    extends 'Test::Shape::Base';
    sub draw { "drawing circle" }
}

my $test_circle = Test::Shape::Circle->new(id => 42);
$test_circle->{type} = 'Circle';

is($test_circle->id, 42, 'Shape reproduction: id method works');
is($test_circle->type, 'Circle', 'Shape reproduction: type method works');
is($test_circle->draw, 'drawing circle', 'Shape reproduction: draw method works');

# Test 8: Cloning with inheritance (the original problem)
{
    package Test::Clone::Parent;
    use Class;
    sub clone_method { "clone_works" }

    package Test::Clone::Child;
    use Class;
    extends 'Test::Clone::Parent';
}

my $original = Test::Clone::Child->new;
my $cloned = bless { %$original }, ref($original);

# This is the key test - cloned objects should still have access to inherited methods
is($cloned->clone_method, 'clone_works',
   'Cloning: cloned objects retain inherited methods');

# Test 9: Complex inheritance chain
{
    package Test::Complex::GrandParent;
    use Class;
    sub grand_method { "grand" }

    package Test::Complex::Parent;
    use Class;
    extends 'Test::Complex::GrandParent';
    sub parent_method { "parent" }

    package Test::Complex::Child;
    use Class;
    extends 'Test::Complex::Parent';
    sub child_method { "child" }
}

my $complex_child = Test::Complex::Child->new;
is($complex_child->grand_method, 'grand', 'Complex inheritance: grandparent method');
is($complex_child->parent_method, 'parent', 'Complex inheritance: parent method');
is($complex_child->child_method, 'child', 'Complex inheritance: own method');

# Test 10: Method resolution order with C3
{
    no strict 'refs';
    my @mro = @{mro::get_linear_isa('Test::Complex::Child')};
    is_deeply(\@mro, ['Test::Complex::Child', 'Test::Complex::Parent', 'Test::Complex::GrandParent'],
              'C3 MRO: correct method resolution order');
}

done_testing;
