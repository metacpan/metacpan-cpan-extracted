#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 'lib';

{
    package TestParent;
    use Class::More;

    has 'common_attr' => (default => 'parent_common');
    has 'parent_only' => (default => 'parent_value');
}

{
    package TestChild;
    use Class::More;

    extends 'TestParent';

    has 'common_attr' => (default => 'child_common');
    has 'child_only' => (default => 'child_value');
}

my $child = TestChild->new();
is($child->common_attr, 'child_common', 'Child overrides parent attribute default');
is($child->parent_only, 'parent_value', 'Child inherits parent-only attribute');
is($child->child_only, 'child_value', 'Child has its own attributes');

done_testing();
