#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok('Role');
}

# Clean up package variables between tests without causing warnings
sub reset_role_system {
    no strict 'refs';
    no warnings 'once';

    # Using local variables to clear the package global state cleanly
    local %Role::REQUIRED_METHODS = ();
    local %Role::IS_ROLE = ();
    local %Role::EXCLUDED_ROLES = ();
    local %Role::APPLIED_ROLES = ();
    local %Role::METHOD_ALIASES = (); # Ensure aliases are reset too
}

# Test 1: Role that doesn't use Role.pm properly
{
    reset_role_system();

    # Create a package that exists but doesn't use Role
    eval <<'END_PACKAGE';
package BadRole;
sub some_method { "not_a_role" }
1;
END_PACKAGE

    # Make sure the package is loaded
    BadRole->some_method;

    package main;

    # The error message should match the actual output
    throws_ok {
        Role::apply_role('TestClassBad', 'BadRole');
    } qr/(is not a role|Failed to load role)/, "Non-role packages are rejected"; # 1
}

# Test 2: Empty role
{
    reset_role_system();

    package EmptyRole;
    use Role;

    package TestClassEmpty;
    use Class;
    with 'EmptyRole';
    sub some_method { "works" }

    package main;

    my $obj = bless {}, 'TestClassEmpty';
    lives_ok { $obj->some_method() } "Empty role doesn't break composition"; # 2
    ok($obj->does('EmptyRole'), "Empty role is correctly recognized"); # 3
}

# Test 3: Role with normal method names
{
    reset_role_system();

    package NormalRole;
    use Role;
    sub normal_method { "normal_method" }

    package TestClassNormal;
    use Class;
    with 'NormalRole';

    package main;

    my $obj = bless {}, 'TestClassNormal';
    is($obj->normal_method(), "normal_method", "Normal method names work fine"); # 4
    ok($obj->does('NormalRole'), "Role with normal method names works"); # 5
}

# Test 4: Circular role dependencies
{
    reset_role_system();

    package CircleRoleA;
    use Role;
    excludes 'CircleRoleB';

    package CircleRoleB;
    use Role;
    excludes 'CircleRoleA';

    package TestClassCircle;

    package main;

    lives_ok {
        Role::apply_role('TestClassCircle', 'CircleRoleA');
    } "First role applies"; # 6

    throws_ok {
        Role::apply_role('TestClassCircle', 'CircleRoleB');
    } qr/cannot be composed with/, "Circular dependencies prevented by exclusion"; # 7
}

# Test 5: Runtime application to instances
{
    reset_role_system();

    package RuntimeInstanceRole;
    use Role;
    sub runtime_instance_method { "instance_application" }

    package TestClassRuntime;
    use Class;

    package main;

    my $obj = TestClassRuntime->new();

    lives_ok {
        Role::apply_role($obj, 'RuntimeInstanceRole');
    } "Runtime application to instance works"; # 8

    is($obj->runtime_instance_method(), "instance_application",
       "Runtime applied method works on instance"); # 9
}

# Test 6: Method name with special characters
{
    reset_role_system();

    package SpecialMethodRole;
    use Role;
    sub method_with_underscores { "underscores_work" }
    sub MethodWithCaps { "caps_work" }

    package TestClassSpecial;
    use Class;
    with 'SpecialMethodRole';

    package main;

    my $obj = bless {}, 'TestClassSpecial';
    is($obj->method_with_underscores(), "underscores_work", "Underscore methods work"); # 10
    is($obj->MethodWithCaps(), "caps_work", "Capitalized methods work"); # 11
}

# Test 7: Role inheritance without conflict
{
    reset_role_system();

    package InheritedRole;
    use Role;
    sub inherited_method { "inherited" }

    package BaseClass;
    use Class;
    with 'InheritedRole';

    package ChildClass;
    use Class;
    extends 'BaseClass';
    sub child_method { "child" }

    package main;

    my $child = ChildClass->new;
    is($child->inherited_method(), "inherited", "Inherited role method works"); # 12
    is($child->child_method(), "child", "Child class method works"); # 13

    my $base = bless {}, 'BaseClass';
    ok($base->does('InheritedRole'), "Role works in base class"); # 14
}

# Test 8: Test that UNIVERSAL methods are protected
{
    reset_role_system();

    package SafeRole;
    use Role;
    sub safe_method { "safe" }

    package TestClassSafe;
    use Class;
    with 'SafeRole';

    package main;

    my $obj = bless {}, 'TestClassSafe';

    ok($obj->can('safe_method'), "can() method works for role methods"); # 15
    ok($obj->can('does'), "can() method works for Role-added methods"); # 16
    ok($obj->does('SafeRole'), "does() method works"); # 17
    is($obj->safe_method(), "safe", "Role method works"); # 18
}

# Test 9: Required methods validation in edge cases
{
    reset_role_system();

    package RoleWithRequirement;
    use Role;
    requires 'must_implement';
    sub provided_method { "provided" }

    package ClassWithoutRequirement;

    package main;

    throws_ok {
        Role::apply_role('ClassWithoutRequirement', 'RoleWithRequirement');
    } qr/requires method.*that are missing/, "Required methods are properly validated"; # 19
}

# Test 10: Role vs Role Method Conflict
{
    reset_role_system();

    package ConflictRoleA;
    use Role;
    sub conflicting_method { "FROM_A" }

    package ConflictRoleB;
    use Role;
    sub conflicting_method { "FROM_B" }

    package TestClassConflict;

    package main;

    # 1. First role applies fine
    lives_ok {
        Role::apply_role('TestClassConflict', 'ConflictRoleA');
    } "First role applies"; # 20

    # 2. Second role triggers conflict error
    throws_ok {
        Role::apply_role('TestClassConflict', 'ConflictRoleB');
    } qr/Method conflict: method 'conflicting_method' provided by both/,
       "Role vs Role method conflict is fatal like Moo::Role"; # 21
}

done_testing;
