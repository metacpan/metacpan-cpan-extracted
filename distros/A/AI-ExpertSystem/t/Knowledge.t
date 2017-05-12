#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 44;

################################################################################
# Load the class
################################################################################

use_ok('AI::ExpertSystem::Simple::Knowledge');

################################################################################
# Create a Rule incorrectly
################################################################################

eval { my $x = AI::ExpertSystem::Simple::Knowledge->new(); };
like($@, qr/^Knowledge->new\(\) takes 1 argument /, 'Too few arguments');

eval { my $x = AI::ExpertSystem::Simple::Knowledge->new(1,2); };
like($@, qr/^Knowledge->new\(\) takes 1 argument /, 'Too many arguments');

eval { my $x = AI::ExpertSystem::Simple::Knowledge->new(undef); };
like($@, qr/^Knowledge->new\(\) argument 1, \(NAME\) is undefined /, 'Name is undefined');
isnt($@, '', 'Died, incorrect number of arguments');

################################################################################
# Create a Rule correctly
################################################################################

my $x = AI::ExpertSystem::Simple::Knowledge->new('fred');
isa_ok($x, 'AI::ExpertSystem::Simple::Knowledge');

################################################################################
# Can we remember our name
################################################################################

eval { $x->name(1); };
like($@, qr/^Knowledge->name\(\) takes no arguments /, 'Too many arguments');

is($x->name(), 'fred', 'Checking the name');

################################################################################
# Check the question attribute
################################################################################

eval { $x->has_question(1); };
like($@, qr/^Knowledge->has_question\(\) takes no arguments /, 'Too many arguments');

eval { $x->set_question(1); };
like($@, qr/^Knowledge->set_question\(\) takes 2 arguments /, 'Too few arguments');

eval { $x->set_question(undef,2); };
like($@, qr/^Knowledge->set_question\(\) argument 1, \(QUESTION\) is undefined /, 'Question is undefined');

eval { $x->get_question(); };
like($@, qr/^Knowledge->set_question\(\) has not been set /, 'Question not set');

is($x->has_question(), '', 'No question has been set');
$x->set_question('to be or not to be', ('be', 'not'));
is($x->has_question(), '1', 'The question is now set');

eval { $x->set_question('fredfred', (1,2)); };
like($@, qr/^Knowledge->set_question\(\) has already been set /, 'Is already set');

################################################################################
# Check the question attribute
################################################################################

is($x->get_value(), undef, 'The value is unset');
is($x->has_question(), '1', 'The question has not been answered');

eval { $x->set_value(); };
like($@, qr/^Knowledge->set_value\(\) takes 2 argument /, 'Too few arguments');

eval { $x->set_value(1); };
like($@, qr/^Knowledge->set_value\(\) takes 2 argument /, 'Too few arguments');

eval { $x->set_value(1,2,3); };
like($@, qr/^Knowledge->set_value\(\) takes 2 argument /, 'Too many arguments');

eval { $x->set_value(undef,2); };
like($@, qr/^Knowledge->set_value\(\) argument 1, \(VALUE\) is undefined /, 'Value is undefined');

eval { $x->set_value(1,undef); };
like($@, qr/^Knowledge->set_value\(\) argument 2, \(SETTER\) is undefined /, 'Value is undefined');

eval { $x->is_value_set(1); };
like($@, qr/^Knowledge->is_value_set\(\) takes no arguments /, 'Too many arguments');

is($x->is_value_set(), '', 'Value is not set');

$x->set_value('fred', 'banana');

is($x->is_value_set(), '1', 'Value is set');

eval { $x->set_value('fredfred', 'banana'); };
like($@, qr/^Knowledge->set_value\(\) has already been set /, 'Is already set');

eval { $x->get_value(1); };
like($@, qr/^Knowledge->get_value\(\) takes no arguments /, 'Too many arguments');

eval { $x->get_setter(1); };
like($@, qr/^Knowledge->get_setter\(\) takes no arguments /, 'Too many arguments');

is($x->get_value(), 'fred', 'The value is set');
is($x->get_setter(), 'banana', 'The value is set');
is($x->has_question(), '', 'The question has been answered');

################################################################################
# Check the question
################################################################################

eval { $x->get_question(1); };
like($@, qr/^Knowledge->get_question\(\) takes no arguments /, 'Too many arguments');

my ($y, @z) = $x->get_question();

is($y, 'to be or not to be', 'Get the question back');
is(scalar(@z), 2, 'Get the responses back');
is($z[0], 'be', 'Checking response');
is($z[1], 'not', 'Checking response');

################################################################################
# Check the reset method for the value part
################################################################################

eval { $x->reset(1); };
like($@, qr/^Knowledge->reset\(\) takes no arguments /, 'Too many arguments');

$x->reset();

is($x->is_value_set(), '', 'Value is not set');
$x->set_value('fred', '');
is($x->is_value_set(), '1', 'Value is set');

$x->reset();

is($x->is_value_set(), '', 'Value is not set');

################################################################################
# Check the reset method for both parts
################################################################################

$x->reset();

is($x->has_question(), '1', 'The question has been set');
is($x->is_value_set(), '', 'Value is not set');

$x->set_value('fred', '');

is($x->is_value_set(), '1', 'Value is set');
is($x->has_question(), '', 'The question has been answered');
