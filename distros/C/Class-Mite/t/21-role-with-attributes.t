#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 'lib';

# Test 1: Basic role with attributes
{
    package TestRoleWithAttr;
    use Role;

    has 'name' => (required => 1);
    has 'count' => (default => 0);

    sub get_info {
        my ($self) = @_;
        return $self->name . ":" . $self->count;
    }
}

{
    package TestClassWithRole;
    use Class::More;
    with 'TestRoleWithAttr';
}

my $obj1 = eval {
    TestClassWithRole->new(name => 'test');
};
is($@, '', 'Object creation successful');
isa_ok($obj1, 'TestClassWithRole', 'Object is correct class');

is($obj1->name, 'test', 'Role attribute accessor works');
is($obj1->count, 0, 'Role attribute default works');
is($obj1->get_info, 'test:0', 'Role method works');

# Test 2: Method conflicts should still be detected
{
    package ConflictRoleA;
    use Role;
    sub conflicting_method { "A" }
}

{
    package ConflictRoleB;
    use Role;
    sub conflicting_method { "B" }
}

my $conflict_error;
{
    package TestClassConflict;
    use Class::More;

    eval {
        with 'ConflictRoleA', 'ConflictRoleB';
    };
    $conflict_error = $@;
}
like($conflict_error, qr/Method conflict: method 'conflicting_method' provided by both/,
     'Method conflicts between roles are still detected');

# Test 3: 'has' should not cause conflicts between roles
{
    package RoleWithHasA;
    use Role;
    has 'attr_a' => (default => 'A');
    sub method_a { "method_a" }
}

{
    package RoleWithHasB;
    use Role;
    has 'attr_b' => (default => 'B');
    sub method_b { "method_b" }
}

my $multi_role_error;
{
    package TestClassMultipleRoles;
    use Class::More;

    eval {
        with 'RoleWithHasA', 'RoleWithHasB';
    };
    $multi_role_error = $@;
}
is($multi_role_error, '', "'has' does not cause conflicts between roles");

my $obj2 = eval {
    TestClassMultipleRoles->new();
};
is($@, '', 'Object with multiple roles created successfully');
isa_ok($obj2, 'TestClassMultipleRoles', 'Object is correct class');

is($obj2->attr_a, 'A', 'Attribute from first role works');
is($obj2->attr_b, 'B', 'Attribute from second role works');
is($obj2->method_a, 'method_a', 'Method from first role works');
is($obj2->method_b, 'method_b', 'Method from second role works');

# Test 4: Class method should win over role method
{
    package RoleWithMethod;
    use Role;
    sub test_method { "from_role" }
}

{
    package TestClassWins;
    use Class::More;
    with 'RoleWithMethod';

    sub test_method { "from_class" }
}

my $obj3 = eval {
    TestClassWins->new();
};
is($@, '', 'Object with class method created successfully');
isa_ok($obj3, 'TestClassWins', 'Object is correct class');
is($obj3->test_method, 'from_class', 'Class method wins over role method');

# Test 5: Required methods validation
my $required_error;
{
    package RoleRequires;
    use Role;
    requires 'required_method';

    sub provided_method { "provided" }
}

{
    package TestClassMissingRequired;
    use Class::More;

    eval {
        with 'RoleRequires';
    };
    $required_error = $@;
}
like($required_error, qr/requires method.*required_method/,
     'Required method validation works');

{
    package TestClassWithRequired;
    use Class::More;
    with 'RoleRequires';

    sub required_method { "implemented" }
}

my $obj4 = eval {
    TestClassWithRequired->new();
};
is($@, '', 'Object with required method created successfully');
isa_ok($obj4, 'TestClassWithRequired', 'Object is correct class');
is($obj4->provided_method, 'provided', 'Role method works when requirements met');
is($obj4->required_method, 'implemented', 'Required method works');

done_testing;
