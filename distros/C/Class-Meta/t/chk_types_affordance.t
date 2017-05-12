#!/usr/bin/perl -w

##############################################################################
# Set up the tests.
##############################################################################

package Class::Meta::Testing;

use strict;
use Test::More tests => 208;
BEGIN {
    $SIG{__DIE__} = \&Carp::confess;
    use_ok( 'Class::Meta');
    use_ok( 'Class::Meta::Type');
    use_ok( 'Class::Meta::Types::Numeric', 'affordance');
    use_ok( 'Class::Meta::Types::Perl', 'affordance');
    use_ok( 'Class::Meta::Types::String', 'affordance');
    use_ok( 'Class::Meta::Types::Boolean', 'affordance');
    our @ISA = qw(Class::Meta::Attribute);
}

my $obj = bless {};
my $aname = 'foo';
my $i = 0;
my $attr;

##############################################################################
# Create a Class::Meta object. We'll use it to create attributes for testing
# the creation of accessors.
ok( my $cm = Class::Meta->new, "Create Class::Meta object" );

##############################################################################
# Check string data type.
ok( my $type = Class::Meta::Type->new('string'), 'Get string' );
is( $type, Class::Meta::Type->new('STRING'), 'Check lc conversion on key' );
is( $type->key, 'string', "Check string key" );
is( $type->name, 'String', "Check string name" );
is( ref $type->check, 'ARRAY', "Check string check" );

foreach my $chk (@{ $type->check }) {
    is( ref $chk, 'CODE', 'Check string code');
}

# Check to make sure that the accessor is created properly. Start with a
# simple set_ method.
ok( $attr = $cm->add_attribute( name => $aname . ++$i, type => 'string'),
    "Create $aname$i attribute" );
ok( $type->build(__PACKAGE__, $attr, Class::Meta::GETSET),
    "Make simple string set" );
ok( my $mut = UNIVERSAL::can(__PACKAGE__, "set_$aname$i"),
    "String mutator exists");
ok( my $acc = UNIVERSAL::can(__PACKAGE__, "get_$aname$i"),
    "String getter exists");

# Test it.
ok( $obj->$mut('test'), "Set string value" );
is( $obj->$acc, 'test', "Check string value" );

# Make it fail the checks.
eval { $obj->$mut([]) };
ok( my $err = $@, "Got invalid string error" );
like( $err, qr/^Value .* is not a valid string/, 'correct string exception' );

# Check to make sure that the Attribute class accessor coderefs are getting
# created.
ok( my $set = $type->make_attr_set($attr), "Check string attr_set" );
ok( my $get = $type->make_attr_get($attr), "Check string attr_get" );

# Make sure they get and set values correctly.
is( $get->($obj), 'test', "Check string getter" );
ok( $set->($obj, 'bar'), "Check string setter" );
is( $get->($obj), 'bar', "Check string getter again" );

##############################################################################
# Check boolean data type.
ok( $type = Class::Meta::Type->new('boolean'), 'Get boolean' );
is( $type, Class::Meta::Type->new('bool'), 'Check bool alias' );
is( $type->key, 'boolean', "Check boolean key" );
is( $type->name, 'Boolean', "Check boolean name" );
# Boolean is special -- it has no checkers.
ok( ! defined $type->check, "Check boolean check" );

# Check to make sure that the accessor is created properly. Start with a
# simple set_ method.
ok( $attr = $cm->add_attribute( name => $aname . ++$i, type => 'string'),
    "Create $aname$i attribute" );
ok( $type->build(__PACKAGE__, $attr, Class::Meta::GETSET),
    "Make simple boolean set" );
ok( $mut = UNIVERSAL::can(__PACKAGE__, "set_$aname$i\_on"),
    "Boolean on mutator exists");
ok( my $off = UNIVERSAL::can(__PACKAGE__, "set_$aname$i\_off"),
    "Boolean off mutator exists");
ok( $acc = UNIVERSAL::can(__PACKAGE__, "is_$aname$i"),
    "Boolean mutator exists");

# Test it.
ok( $obj->$mut, "Set boolean value on" );
is( $obj->$acc, 1, "Check boolean value on" );
$obj->$off; # Set boolean value off.
is( $obj->$acc, 0, "Check boolean value off" );

# And finally, check to make sure that the Attribute class accessor coderefs
# are getting created.
ok( $set = $type->make_attr_set($attr), "Check boolean attr_set" );
ok( $get = $type->make_attr_get($attr), "Check boolean attr_get" );

# Make sure they get and set values correctly.
is( $get->($obj), 0, "Check boolean getter" );
$set->($obj, 12);
is( $get->($obj), 1, "Check boolean getter again" );

##############################################################################
# Check whole data type.
ok( $type = Class::Meta::Type->new('whole'), 'Get whole' );
is( $type->key, 'whole', "Check whole key" );
is( $type->name, 'Whole Number', "Check whole name" );
is( ref $type->check, 'ARRAY', "Check whole check" );
foreach my $chk (@{ $type->check }) {
    is( ref $chk, 'CODE', 'Check whole code');
}

# Check to make sure that the accessor is created properly. Start with a
# simple set_ method.
ok( $attr = $cm->add_attribute( name => $aname . ++$i, type => 'string'),
    "Create $aname$i attribute" );
ok( $type->build(__PACKAGE__, $attr, Class::Meta::GETSET),
    "Make simple whole set" );
ok( $mut = UNIVERSAL::can(__PACKAGE__, "set_$aname$i"),
    "Whole mutator exists");
ok( $acc = UNIVERSAL::can(__PACKAGE__, "get_$aname$i"),
    "Whole getter exists");

# Test it.
ok( $obj->$mut(12), "Set whole value" );
is( $obj->$acc, 12, "Check whole value" );

# Make it fail the checks.
eval { $obj->$mut(-12) };
ok( $err = $@, "Got invalid whole error" );
like( $err, qr/^Value .* is not a valid whole number/,
      'correct whole exception' );

# Check to make sure that the Attribute class accessor coderefs are getting
# created.
ok( $set = $type->make_attr_set($attr), "Check whole attr_set" );
ok( $get = $type->make_attr_get($attr), "Check whole attr_get" );

# Make sure they get and set values correctly.
is( $get->($obj), 12, "Check whole getter" );
ok( $set->($obj, 100), "Check whole setter" );
is( $get->($obj), 100, "Check whole getter again" );

##############################################################################
# Check integer data type.
ok( $type = Class::Meta::Type->new('integer'), 'Get integer' );
is( $type, Class::Meta::Type->new('int'), 'Check int alias' );
is( $type->key, 'integer', "Check integer key" );
is( $type->name, 'Integer', "Check integer name" );
is( ref $type->check, 'ARRAY', "Check integer check" );
foreach my $chk (@{ $type->check }) {
    is( ref $chk, 'CODE', 'Check integer code');
}

# Check to make sure that the accessor is created properly. Start with a
# simple set_ method.
ok( $attr = $cm->add_attribute( name => $aname . ++$i, type => 'string'),
    "Create $aname$i attribute" );
ok( $type->build(__PACKAGE__, $attr, Class::Meta::GETSET),
    "Make simple integer set" );
ok( $mut = UNIVERSAL::can(__PACKAGE__, "set_$aname$i"),
    "Integer mutator exists");
ok( $acc = UNIVERSAL::can(__PACKAGE__, "get_$aname$i"),
    "Integer getter exists");

# Test it.
ok( $obj->$mut(12), "Set integer value" );
is( $obj->$acc, 12, "Check integer value" );

# Make it fail the checks.
eval { $obj->$mut(12.2) };
ok( $err = $@, "Got invalid integer error" );
like( $err, qr/^Value .* is not a valid integer/,
      'correct integer exception' );

# Check to make sure that the Attribute class accessor coderefs are getting
# created.
ok( $set = $type->make_attr_set($attr), "Check integer attr_set" );
ok( $get = $type->make_attr_get($attr), "Check integer attr_get" );

# Make sure they get and set values correctly.
is( $get->($obj), 12, "Check integer getter" );
ok( $set->($obj, -100), "Check integer setter" );
is( $get->($obj), -100, "Check integer getter again" );

##############################################################################
# Check decimal data type.
ok( $type = Class::Meta::Type->new('decimal'), 'Get decimal' );
is( $type, Class::Meta::Type->new('dec'), 'Check dec alias' );
is( $type->key, 'decimal', "Check decimal key" );
is( $type->name, 'Decimal Number', "Check decimal name" );
is( ref $type->check, 'ARRAY', "Check decimal check" );
foreach my $chk (@{ $type->check }) {
    is( ref $chk, 'CODE', 'Check decimal code');
}

# Check to make sure that the accessor is created properly. Start with a
# simple set_ method.
ok( $attr = $cm->add_attribute( name => $aname . ++$i, type => 'string'),
    "Create $aname$i attribute" );
ok( $type->build(__PACKAGE__, $attr, Class::Meta::GETSET),
    "Make simple decimal set" );
ok( $mut = UNIVERSAL::can(__PACKAGE__, "set_$aname$i"),
    "Decimal mutator exists");
ok( $acc = UNIVERSAL::can(__PACKAGE__, "get_$aname$i"),
    "Decimal getter exists");

# Test it.
ok( $obj->$mut(12.2), "Set decimal value" );
is( $obj->$acc, 12.2, "Check decimal value" );

# Make it fail the checks.
eval { $obj->$mut('foo') };
ok( $err = $@, "Got invalid decimal error" );
like( $err, qr/^Value .* is not a valid decimal/,
      'correct decimal exception' );

# Check to make sure that the Attribute class accessor coderefs are getting
# created.
ok( $set = $type->make_attr_set($attr), "Check decimal attr_set" );
ok( $get = $type->make_attr_get($attr), "Check decimal attr_get" );

# Make sure they get and set values correctly.
is( $get->($obj), 12.2, "Check decimal getter" );
ok( $set->($obj, +100.23), "Check decimal setter" );
is( $get->($obj), +100.23, "Check decimal getter again" );

##############################################################################
# Check float data type.
ok( $type = Class::Meta::Type->new('float'), 'Get float' );
is( $type->key, 'float', "Check float key" );
is( $type->name, 'Floating Point Number', "Check float name" );
is( ref $type->check, 'ARRAY', "Check float check" );
foreach my $chk (@{ $type->check }) {
    is( ref $chk, 'CODE', 'Check float code');
}

# Check to make sure that the accessor is created properly. Start with a
# simple set_ method.
ok( $attr = $cm->add_attribute( name => $aname . ++$i, type => 'string'),
    "Create $aname$i attribute" );
ok( $type->build(__PACKAGE__, $attr, Class::Meta::GETSET),
    "Make simple float set" );
ok( $mut = UNIVERSAL::can(__PACKAGE__, "set_$aname$i"),
    "Float mutator exists");
ok( $acc = UNIVERSAL::can(__PACKAGE__, "get_$aname$i"),
    "Float getter exists");

# Test it.
ok( $obj->$mut(1.23e99), "Set float value" );
is( $obj->$acc, 1.23e99, "Check float value" );

# Make it fail the checks.
eval { $obj->$mut('foo') };
ok( $err = $@, "Got invalid float error" );
like( $err, qr/^Value .* is not a valid float/,
      'correct float exception' );

# Check to make sure that the Attribute class accessor coderefs are getting
# created.
ok( $set = $type->make_attr_set($attr), "Check float attr_set" );
ok( $get = $type->make_attr_get($attr), "Check float attr_get" );

# Make sure they get and set values correctly.
is( $get->($obj), 1.23e99, "Check float getter" );
ok( $set->($obj, -100.23543), "Check float setter" );
is( $get->($obj), -100.23543, "Check float getter again" );

##############################################################################
# Check scalar data type.
ok( $type = Class::Meta::Type->new('scalar'), 'Get scalar' );
is( $type->key, 'scalar', "Check scalar key" );
is( $type->name, 'Scalar', "Check scalar name" );
# Scalars aren't validated or convted.
ok( ! defined $type->check, "Check scalar check" );

# Check to make sure that the accessor is created properly. Start with a
# simple set_ method.
ok( $attr = $cm->add_attribute( name => $aname . ++$i, type => 'string'),
    "Create $aname$i attribute" );
ok( $type->build(__PACKAGE__, $attr, Class::Meta::GETSET),
    "Make simple scalar set" );
ok( $mut = UNIVERSAL::can(__PACKAGE__, "set_$aname$i"),
    "Scalar mutator exists");
ok( $acc = UNIVERSAL::can(__PACKAGE__, "get_$aname$i"),
    "Scalar getter exists");

# Test it.
ok( $obj->$mut('foo'), "Set scalar value" );
is( $obj->$acc, 'foo', "Check scalar value" );

# Check to make sure that the Attribute class accessor coderefs are getting
# created.
ok( $set = $type->make_attr_set($attr), "Check scalar attr_set" );
ok( $get = $type->make_attr_get($attr), "Check scalar attr_get" );

# Make sure they get and set values correctly.
is( $get->($obj), 'foo', "Check scalar getter" );
ok( $set->($obj, []), "Check scalar setter" );
is( ref $get->($obj), 'ARRAY', "Check scalar getter again" );

##############################################################################
# Check scalar reference data type.
ok( $type = Class::Meta::Type->new('scalarref'), 'Get scalar ref' );
is( $type->key, 'scalarref', "Check scalar ref key" );
is( $type->name, 'Scalar Reference', "Check scalar ref name" );
is( ref $type->check, 'ARRAY', "Check scalar ref check" );
foreach my $chk (@{ $type->check }) {
    is( ref $chk, 'CODE', 'Check scalar ref code');
}

# Check to make sure that the accessor is created properly. Start with a
# simple set_ method.
ok( $attr = $cm->add_attribute( name => $aname . ++$i, type => 'string'),
    "Create $aname$i attribute" );
ok( $type->build(__PACKAGE__, $attr, Class::Meta::GETSET),
    "Make simple scalarref set" );
ok( $mut = UNIVERSAL::can(__PACKAGE__, "set_$aname$i"),
    "Scalarref mutator exists");
ok( $acc = UNIVERSAL::can(__PACKAGE__, "get_$aname$i"),
    "Scalarref getter exists");

# Test it.
my $sref = \"foo";
ok( $obj->$mut($sref), "Set scalarref value" );
is( $obj->$acc, $sref, "Check scalarref value" );

# Make it fail the checks.
eval { $obj->$mut('foo') };
ok( $err = $@, "Got invalid scalarref error" );
like( $err, qr/^Value .* is not a valid Scalar Reference/,
      'correct scalarref exception' );

# Check to make sure that the Attribute class accessor coderefs are getting
# created.
ok( $set = $type->make_attr_set($attr), "Check scalarref attr_set" );
ok( $get = $type->make_attr_get($attr), "Check scalarref attr_get" );

# Make sure they get and set values correctly.
is( $get->($obj), $sref, "Check scalarref getter" );
$sref = \"bar";
ok( $set->($obj, $sref), "Check scalarref setter" );
is( $get->($obj), $sref, "Check scalarref getter again" );

##############################################################################
# Check array data type.
ok( $type = Class::Meta::Type->new('array'), 'Get array' );
is( $type, Class::Meta::Type->new('arrayref'), 'Check arrayref alias' );
is( $type->key, 'array', "Check array key" );
is( $type->name, 'Array Reference', "Check array name" );
is( ref $type->check, 'ARRAY', "Check array check" );
foreach my $chk (@{ $type->check }) {
    is( ref $chk, 'CODE', 'Check array code');
}

# Check to make sure that the accessor is created properly. Start with a
# simple set_ method.
ok( $attr = $cm->add_attribute( name => $aname . ++$i, type => 'string'),
    "Create $aname$i attribute" );
ok( $type->build(__PACKAGE__, $attr, Class::Meta::GETSET),
    "Make simple arrayref set" );
ok( $mut = UNIVERSAL::can(__PACKAGE__, "set_$aname$i"),
    "Arrayref mutator exists");
ok( $acc = UNIVERSAL::can(__PACKAGE__, "get_$aname$i"),
    "Arrayref getter exists");

# Test it.
my $aref = [1,2,3];
ok( $obj->$mut($aref), "Set arrayref value" );
is( $obj->$acc, $aref, "Check arrayref value" );

# Make it fail the checks.
eval { $obj->$mut('foo') };
ok( $err = $@, "Got invalid arrayref error" );
like( $err, qr/^Value .* is not a valid Array Reference/,
      'correct arrayref exception' );

# Check to make sure that the Attribute class accessor coderefs are getting
# created.
ok( $set = $type->make_attr_set($attr), "Check arrayref attr_set" );
ok( $get = $type->make_attr_get($attr), "Check arrayref attr_get" );

# Make sure they get and set values correctly.
is( $get->($obj), $aref, "Check arrayref getter" );
$aref = [4,5,6];
ok( $set->($obj, $aref), "Check arrayref setter" );
is( $get->($obj), $aref, "Check arrayref getter again" );

##############################################################################
# Check hash data type.
ok( $type = Class::Meta::Type->new('hash'), 'Get hash' );
is( $type, Class::Meta::Type->new('hashref'), 'Check hashref alias' );
is( $type->key, 'hash', "Check hash key" );
is( $type->name, 'Hash Reference', "Check hash name" );
is( ref $type->check, 'ARRAY', "Check hash check" );
foreach my $chk (@{ $type->check }) {
    is( ref $chk, 'CODE', 'Check hash code');
}

# Check to make sure that the accessor is created properly. Start with a
# simple set_ method.
ok( $attr = $cm->add_attribute( name => $aname . ++$i, type => 'string'),
    "Create $aname$i attribute" );
ok( $type->build(__PACKAGE__, $attr, Class::Meta::GETSET),
    "Make simple hashref set" );
ok( $mut = UNIVERSAL::can(__PACKAGE__, "set_$aname$i"),
    "Hashref mutator exists");
ok( $acc = UNIVERSAL::can(__PACKAGE__, "get_$aname$i"),
    "Hashref getter exists");

# Test it.
my $href = {};
ok( $obj->$mut($href), "Set hashref value" );
is( $obj->$acc, $href, "Check hashref value" );

# Make it fail the checks.
eval { $obj->$mut('foo') };
ok( $err = $@, "Got invalid hashref error" );
like( $err, qr/^Value .* is not a valid Hash Reference/,
      'correct hashref exception' );

# Check to make sure that the Attribute class accessor coderefs are getting
# created.
ok( $set = $type->make_attr_set($attr), "Check hashref attr_set" );
ok( $get = $type->make_attr_get($attr), "Check hashref attr_get" );

# Make sure they get and set values correctly.
is( $get->($obj), $href, "Check hashref getter" );
$href = { foo => 'bar' };
ok( $set->($obj, $href), "Check hashref setter" );
is( $get->($obj), $href, "Check hashref getter again" );

##############################################################################
# Check code data type.
ok( $type = Class::Meta::Type->new('code'), 'Get code' );
is( $type, Class::Meta::Type->new('coderef'), 'Check coderef alias' );
is( $type, Class::Meta::Type->new('closure'), 'Check closure alias' );
is( $type->key, 'code', "Check code key" );
is( $type->name, 'Code Reference', "Check code name" );
is( ref $type->check, 'ARRAY', "Check code check" );
foreach my $chk (@{ $type->check }) {
    is( ref $chk, 'CODE', 'Check code code');
}

# Check to make sure that the accessor is created properly. Start with a
# simple set_ method.
ok( $attr = $cm->add_attribute( name => $aname . ++$i, type => 'string'),
    "Create $aname$i attribute" );
ok( $type->build(__PACKAGE__, $attr, Class::Meta::GETSET),
    "Make simple coderef set" );
ok( $mut = UNIVERSAL::can(__PACKAGE__, "set_$aname$i"),
    "Coderef mutator exists");
ok( $acc = UNIVERSAL::can(__PACKAGE__, "get_$aname$i"),
    "Coderef getter exists");

# Test it.
my $cref = sub {};
ok( $obj->$mut($cref), "Set coderef value" );
is( $obj->$acc, $cref, "Check coderef value" );

# Make it fail the checks.
eval { $obj->$mut('foo') };
ok( $err = $@, "Got invalid coderef error" );
like( $err, qr/^Value .* is not a valid Code Reference/,
      'correct coderef exception' );

# Check to make sure that the Attribute class accessor coderefs are getting
# created.
ok( $set = $type->make_attr_set($attr), "Check coderef attr_set" );
ok( $get = $type->make_attr_get($attr), "Check coderef attr_get" );

# Make sure they get and set values correctly.
is( $get->($obj), $cref, "Check coderef getter" );
$cref = sub { 'foo' };
ok( $set->($obj, $cref), "Check coderef setter" );
is( $get->($obj), $cref, "Check coderef getter again" );
