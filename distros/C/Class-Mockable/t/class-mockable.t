use strict;
use warnings;
use lib 't/lib';

# use Carp;
# BEGIN { $SIG{ __DIE__ } = sub { Carp::confess( @_ ) }; }

use Test::More tests => 15;

use SomePackage;

is(SomePackage->get_returnvalue(), 94, "default works");

SomePackage->_returnvalue('lemon');
is(SomePackage->get_returnvalue(), 'lemon', "overriding the default works");

SomePackage->_reset_returnvalue();
is(SomePackage->get_returnvalue(), 94, "reset works");


# Method mocking tests.
ok(SomePackage->can('_wrapped_method'), 'Mock method accessor created ok');
ok(SomePackage->can('_set_wrapped_method'), 'Mock method setter created ok');
ok(SomePackage->can('_reset_wrapped_method'), 'Mock method resetter created ok');

is(SomePackage->_wrapped_method(), 'wrapped method', 'Default mock method calls correct sub');

SomePackage->_set_wrapped_method(sub{ return "other method, called on $_[0] with $_[1]" });
is(SomePackage->_wrapped_method("foo"), 'other method, called on SomePackage with foo', 'Method mocking works correctly');

SomePackage->_reset_wrapped_method();
is(SomePackage->_wrapped_method(), 'wrapped method', 'Method mocking reset works correctly');

# Inherited method mocking tests.
ok(SomePackage->can('_wrapped_method_in_parent'), 'Mock method accessor created ok');
ok(SomePackage->can('_set_wrapped_method_in_parent'), 'Mock method setter created ok');
ok(SomePackage->can('_reset_wrapped_method_in_parent'), 'Mock method resetter created ok');

is(SomePackage->_wrapped_method_in_parent("bar"), 'wrapped method in parent, called on SomePackage', 'Default mock method calls correct sub');

SomePackage->_set_wrapped_method_in_parent(sub{ return "other method, called on $_[0] with $_[1]" });
is(SomePackage->_wrapped_method_in_parent("foo"), 'other method, called on SomePackage with foo', 'Method mocking works correctly');

SomePackage->_reset_wrapped_method_in_parent();
is(SomePackage->_wrapped_method_in_parent("bar"), 'wrapped method in parent, called on SomePackage', 'Method mocking reset works correctly');

