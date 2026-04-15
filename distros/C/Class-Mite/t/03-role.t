#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/";

# ----------------------------------------------------------------------
# 1. Basic Role Application
# ----------------------------------------------------------------------
eval { require TestClass::Basic; };
is($@, '', 'SUCCESS: TestClass::Basic loaded successfully with role');

my $basic_obj = TestClass::Basic->new;

isa_ok($basic_obj, 'TestClass::Basic', 'TestClass::Basic object created');
can_ok('TestClass::Basic', 'common_method');
is($basic_obj->common_method, 'Basic', 'Role method returns correct value');
is($basic_obj->class_method, 'Class', 'Class method is intact');
ok($basic_obj->does('TestRole::Basic'), 'TestClass::Basic does TestRole::Basic');


# ----------------------------------------------------------------------
# 2. Required Methods Check (Should fail - TestClass::Requires::Fail)
# ----------------------------------------------------------------------
eval { require TestClass::Requires::Fail; };
like($@, qr/Role 'TestRole::Requires' requires method\(s\) that are missing.*mandatory_method/,
    'FAIL: Applying role with missing required methods dies with correct error');


# Required Methods Check (Should succeed - TestClass::Requires::Success)
eval { require TestClass::Requires::Success; };
is($@, '', 'SUCCESS: TestClass::Requires::Success loaded with all required methods implemented');
can_ok('TestClass::Requires::Success', 'required_method_body');


# ----------------------------------------------------------------------
# 3. Exclusion Conflict Check (Should fail)
# ----------------------------------------------------------------------
eval { require TestClass::Excludes::Fail; };
like($@, qr/Role 'TestRole::Excludes' cannot be composed with role\(s\): TestRole::Basic/,
    'FAIL: Applying excluded role dies with correct error');


# ----------------------------------------------------------------------
# 4. Method Conflict Check (Now Fatal Like Moo::Role)
# ----------------------------------------------------------------------
# TestClass::Conflict::Fatal applies TestRole::Basic then TestRole::Conflicting.
# These both provide 'common_method', so the composition should FAIL.

local $@;
eval { require TestClass::Conflict::Fatal; };

like($@, qr/Method conflict: method 'common_method' provided by both 'TestRole::Basic' and 'TestRole::Conflicting'/,
    'FATAL: Applying conflicting roles without alias/excludes dies with correct error');


# ----------------------------------------------------------------------
# 5. Method Aliasing (Should succeed)
# ----------------------------------------------------------------------
eval { require TestClass::Conflict::Aliased; };
is($@, '', 'SUCCESS: Method conflict resolved with aliasing and class loaded');

my $aliased_obj = TestClass::Conflict::Aliased->new;
is($aliased_obj->common_method, 'Basic', 'Aliased role: Original method from first role is retained');
can_ok('TestClass::Conflict::Aliased', 'conflicting_method_aliased');
is($aliased_obj->conflicting_method_aliased, 'Conflicting', 'Aliased role: Conflicting method is installed under alias');


# ----------------------------------------------------------------------
# 6. Alias Conflict (Should fail if alias target already exists)
# ----------------------------------------------------------------------
eval { require TestClass::Alias::Conflict; };
like(
    $@,
    qr/Method conflict:.*aliased to common_method.*between TestRole::Basic and TestRole::Conflicting/,
    'FATAL: Alias target conflict dies with correct error'
);


# ----------------------------------------------------------------------
# 7. Runtime apply_role and does()
# ----------------------------------------------------------------------
{
    package Class::Runtime;
    use Class;
}

ok(!Class::Runtime->new->does('TestRole::Basic'), 'does() returns false before runtime application');

eval {
    Role::apply_role('Class::Runtime', 'TestRole::Basic');
};
is($@, '', 'SUCCESS: Runtime role application works');

my $runtime_obj = Class::Runtime->new;
ok($runtime_obj->does('TestRole::Basic'), 'does() returns true after runtime application');
can_ok('Class::Runtime', 'common_method');

done_testing;
