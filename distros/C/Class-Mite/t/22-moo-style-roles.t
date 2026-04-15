#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 'lib';

# Test 1: Check if Role is loading properly
print "=== COMPREHENSIVE ROLE ATTRIBUTE DEBUG ===\n";
print "1. Checking Role module...\n";
eval { require Role };
if ($@) {
    print "   ERROR: Cannot load Role: $@\n";
} else {
    print "   SUCCESS: Role module loaded\n";
    print "   Role::VERSION: $Role::VERSION\n";
}

# Test 2: Create a role with attributes
print "2. Creating role with attributes...\n";
{
    package DebugRole;
    use Role;

    has 'debug_attr' => (default => 'debug_value');
    has 'required_attr' => (required => 1);

    print "   Role package: DebugRole\n";
    print "   IS_ROLE flag: " . ($Role::IS_ROLE{'DebugRole'} ? 'YES' : 'NO') . "\n";
    print "   ROLE_ATTRIBUTES: " .
         (exists $Role::ROLE_ATTRIBUTES{'DebugRole'} ?
          join(', ', keys %{$Role::ROLE_ATTRIBUTES{'DebugRole'}}) : 'NONE') . "\n";
}

# Test 3: Create a class that uses the role
print "3. Creating class that consumes role...\n";
{
    package DebugClass;
    use Class::More;
    with 'DebugRole';

    print "   Class package: DebugClass\n";
    print "   APPLIED_ROLES: " .
         (exists $Role::APPLIED_ROLES{'DebugClass'} ?
          join(', ', @{$Role::APPLIED_ROLES{'DebugClass'}}) : 'NONE') . "\n";
    print "   Class::More ATTRIBUTES: " .
         (exists $Class::More::ATTRIBUTES{'DebugClass'} ?
          join(', ', keys %{$Class::More::ATTRIBUTES{'DebugClass'}}) : 'NONE') . "\n";
}

# Test 4: Check what _get_all_attributes returns
print "4. Testing _get_all_attributes...\n";
my $all_attrs = eval { Class::More::_get_all_attributes('DebugClass') };
if ($@) {
    print "   ERROR: _get_all_attributes failed: $@\n";
} else {
    print "   SUCCESS: _get_all_attributes returned: " .
         (keys %$all_attrs ? join(', ', keys %$all_attrs) : 'NO ATTRIBUTES') . "\n";
    foreach my $attr (keys %$all_attrs) {
        print "     $attr: " .
             "required=" . ($all_attrs->{$attr}{required} ? 'YES' : 'NO') . ", " .
             "default=" . ($all_attrs->{$attr}{default} // 'UNDEF') . "\n";
    }
}

# Test 5: Try to create object with required attribute
print "5. Testing object creation with required attribute...\n";
my $obj1 = eval {
    DebugClass->new(required_attr => 'test_value');
};

if ($@) {
    print "   ERROR: Object creation failed: $@\n";
} else {
    print "   SUCCESS: Object created\n";
    print "   Object keys: " . join(', ', keys %$obj1) . "\n";
    print "   required_attr value: " . ($obj1->{required_attr} // 'UNDEF') . "\n";
    print "   debug_attr value: " . ($obj1->{debug_attr} // 'UNDEF') . "\n";
}

is($@, '', 'Object creation with required attribute works');
isa_ok($obj1, 'DebugClass') if $obj1;

# Test 6: Check if accessors work
print "6. Testing accessors...\n";
if ($obj1) {
    my $required_val = eval { $obj1->required_attr };
    print "   required_attr accessor: " . ($required_val // 'UNDEF') .
          ( $@ ? " (error: $@)" : "" ) . "\n";

    my $debug_val = eval { $obj1->debug_attr };
    print "   debug_attr accessor: " . ($debug_val // 'UNDEF') .
          ( $@ ? " (error: $@)" : "" ) . "\n";

    is($required_val, 'test_value', 'Required attribute accessor works');
    is($debug_val, 'debug_value', 'Default attribute accessor works');
} else {
    fail("Cannot test accessors - object not created");
}

# Test 7: Test missing required attribute
print "7. Testing missing required attribute...\n";
my $obj2 = eval {
    DebugClass->new();  # Missing required_attr
};
print "   Expected error: $@" if $@;
like($@, qr/Required attribute/, 'Missing required attribute fails properly');

# Test 8: Test multiple roles
print "8. Testing multiple roles...\n";
{
    package RoleA;
    use Role;
    has 'attr_a' => (default => 'A');

    package RoleB;
    use Role;
    has 'attr_b' => (default => 'B');

    package MultiClass;
    use Class::More;
    with 'RoleA', 'RoleB';

    print "   MultiClass APPLIED_ROLES: " .
         (exists $Role::APPLIED_ROLES{'MultiClass'} ?
          join(', ', @{$Role::APPLIED_ROLES{'MultiClass'}}) : 'NONE') . "\n";
}

my $multi_attrs = eval { Class::More::_get_all_attributes('MultiClass') };
print "   MultiClass all attributes: " .
     (keys %$multi_attrs ? join(', ', keys %$multi_attrs) : 'NONE') . "\n";

my $multi_obj = eval {
    MultiClass->new();
};
if ($@) {
    print "   ERROR: Multi-role object creation failed: $@\n";
} else {
    print "   SUCCESS: Multi-role object created\n";
    print "   Object keys: " . join(', ', keys %$multi_obj) . "\n";
}

is($@, '', 'Multiple roles with attributes work');
if ($multi_obj) {
    my $val_a = eval { $multi_obj->attr_a };
    my $val_b = eval { $multi_obj->attr_b };
    print "   attr_a value: " . ($val_a // 'UNDEF') . "\n";
    print "   attr_b value: " . ($val_b // 'UNDEF') . "\n";
    is($val_a, 'A', 'Attribute from first role works');
    is($val_b, 'B', 'Attribute from second role works');
} else {
    fail("Multi-role object not created");
}

done_testing();
