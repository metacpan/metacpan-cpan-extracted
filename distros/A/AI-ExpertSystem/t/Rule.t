#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 37;

use_ok('AI::ExpertSystem::Simple::Rule');

################################################################################
# Create a new rule
################################################################################

my $x;

eval { $x = AI::ExpertSystem::Simple::Rule->new(); };
like($@, qr/^Rule->new\(\) takes 1 argument /, 'Too few arguments');

eval { $x = AI::ExpertSystem::Simple::Rule->new(1,2); };
like($@, qr/^Rule->new\(\) takes 1 argument /, 'Too many arguments');

eval { $x = AI::ExpertSystem::Simple::Rule->new(undef); };
like($@, qr/^Rule->new\(\) argument 1 \(NAME\) is undefined /, 'Name is undefined');

$x = AI::ExpertSystem::Simple::Rule->new('fred');

isa_ok($x, 'AI::ExpertSystem::Simple::Rule');

eval { $x->name(1); };
like($@, qr/^Rule->name\(\) takes no arguments /, 'Too many arguments');

is($x->name(), 'fred', 'Checking the name');

################################################################################
# Populate the rule
################################################################################

eval { $x->add_condition(1); };
like($@, qr/^Rule->add_condition\(\) takes 2 arguments /, 'Too few arguments');

eval { $x->add_condition(1, 2, 3); };
like($@, qr/^Rule->add_condition\(\) takes 2 arguments /, 'Too many arguments');

eval { $x->add_condition(undef, 2); };
like($@, qr/^Rule->add_condition\(\) argument 1 \(NAME\) is undefined /, 'Name is undefined');

eval { $x->add_condition(1, undef); };
like($@, qr/^Rule->add_condition\(\) argument 2 \(VALUE\) is undefined /, 'Value is undefined');

$x->add_condition('a', 1);

eval { $x->add_condition('a', 1); };
like($@, qr/^Rule->add_condition\(\) has already been set /, 'Is already set');

$x->add_condition('b', 2);

eval { $x->add_action(1); };
like($@, qr/^Rule->add_action\(\) takes 2 arguments /, 'Too few arguments');

eval { $x->add_action(1, 2, 3); };
like($@, qr/^Rule->add_action\(\) takes 2 arguments /, 'Too many arguments');

eval { $x->add_action(undef, 2); };
like($@, qr/^Rule->add_action\(\) argument 1 \(NAME\) is undefined /, 'Name is undefined');

eval { $x->add_action(1, undef); };
like($@, qr/^Rule->add_action\(\) argument 2 \(VALUE\) is undefined /, 'Value is undefined');

$x->add_action('c', 3);

eval { $x->add_action('c', 3); };
like($@, qr/^Rule->add_action\(\) has already been set /, 'Is already set');

eval { $x->state(1); };
like($@, qr/^Rule->state\(\) takes no arguments /, 'Too many arguments');

is($x->state(), 'active', 'Is the rule active');

eval { $x->unresolved(1); };
like($@, qr/^Rule->unresolved\(\) takes no arguments /, 'Too many arguments');

is(scalar($x->unresolved()), 2, 'Unresolved list');

eval { $x->given(1); };
like($@, qr/^Rule->given\(\) takes 2 arguments /, 'Too few arguments');

eval { $x->given(1, 2, 3); };
like($@, qr/^Rule->given\(\) takes 2 arguments /, 'Too many arguments');

eval { $x->given(undef, 2); };
like($@, qr/^Rule->given\(\) argument 1 \(NAME\) is undefined /, 'Name is undefined');

eval { $x->given(1, undef); };
like($@, qr/^Rule->given\(\) argument 2 \(VALUE\) is undefined /, 'Value is undefined');

is($x->given('b', 2), 'active', 'Is the rule still active');

is(scalar($x->unresolved()), 1, 'Unresolved list');

is($x->given('a', 1), 'completed', 'Is the rule now complete');

is(scalar($x->unresolved()), 0, 'Unresolved list');

################################################################################
# Reset the rule and start again
################################################################################

eval { $x->reset(1); };
like($@, qr/^Rule->reset\(\) takes no arguments /, 'Too many arguments');

$x->reset();

is($x->state(), 'active', 'Is the rule active');

is($x->given('b', 1), 'invalid', 'Is the rule now invalid');

################################################################################
# Check the results
################################################################################

eval { $x->actions(1); };
like($@, qr/^Rule->actions\(\) takes no arguments /, 'Too many arguments');

my %r = $x->actions();

is(scalar keys %r, 1, 'Check the action is ok');
is($r{c}, 3, 'Check the action is ok');

eval { $x->conditions(1); };
like($@, qr/^Rule->conditions\(\) takes no arguments /, 'Too many arguments');

%r = $x->conditions();

is(scalar keys %r, 2, 'Check the action is ok');
