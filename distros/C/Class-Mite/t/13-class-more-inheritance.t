#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use lib 'lib';

# Test inheritance with attributes
{
    package Test::Parent;
    use Class::More;

    has parent_attr => (default => 'parent_value');
    has common_attr => (default => 'parent_common');

    sub parent_method { 'from_parent' }
    sub common_method { 'parent_common_method' }
}

{
    package Test::Child;
    use Class::More;
    extends 'Test::Parent';

    has child_attr => (default => 'child_value');
    has common_attr => (default => 'child_common'); # Override parent default

    sub child_method { 'from_child' }
    sub common_method { 'child_common_method' } # Override parent method
}

my $child = Test::Child->new();
isa_ok($child, 'Test::Child', 'Child object created');
isa_ok($child, 'Test::Parent', 'Child inherits from parent');

# Test attribute inheritance
is($child->parent_attr, 'parent_value', 'Inherited parent attribute works');
is($child->child_attr, 'child_value', 'Child attribute works');
is($child->common_attr, 'child_common', 'Child overrides parent attribute default');

# Test method inheritance
is($child->parent_method, 'from_parent', 'Inherited parent method works');
is($child->child_method, 'from_child', 'Child method works');
is($child->common_method, 'child_common_method', 'Child overrides parent method');

# Test BUILD method inheritance
{
    package Test::BuildParent;
    use Class::More;

    has build_log => (default => '');

    sub BUILD {
        my ($self) = @_;
        $self->{build_log} .= 'parent:';
    }
}

{
    package Test::BuildChild;
    use Class::More;
    extends 'Test::BuildParent';

    sub BUILD {
        my ($self) = @_;
        $self->{build_log} .= 'child:';
    }
}

my $build_child = Test::BuildChild->new();
is($build_child->{build_log}, 'parent:child:', 'BUILD methods called in correct order');

# Test multiple inheritance
{
    package Test::Multi1;
    use Class::More;
    has multi1 => (default => 'from_multi1');
}

{
    package Test::Multi2;
    use Class::More;
    has multi2 => (default => 'from_multi2');
}

{
    package Test::MultiChild;
    use Class::More;
    extends qw(Test::Multi1 Test::Multi2);
}

my $multi = Test::MultiChild->new();
is($multi->multi1, 'from_multi1', 'Multiple inheritance - first parent');
is($multi->multi2, 'from_multi2', 'Multiple inheritance - second parent');

done_testing;
