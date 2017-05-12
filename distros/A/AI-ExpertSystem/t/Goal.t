#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 18;

################################################################################
# Load the class
################################################################################

use_ok('AI::ExpertSystem::Simple::Goal');

################################################################################
# Create a AI::ExpertSystem::Simple::Goal incorrectly
################################################################################

eval { my $x = AI::ExpertSystem::Simple::Goal->new(); };
like($@, qr/^Goal->new\(\) takes 2 arguments /, 'Too few arguments');

eval { my $x = AI::ExpertSystem::Simple::Goal->new('fred'); };
like($@, qr/^Goal->new\(\) takes 2 arguments /, 'Too few arguments');

eval { my $x = AI::ExpertSystem::Simple::Goal->new('fred', 'a message', 'that is too long'); };
like($@, qr/^Goal->new\(\) takes 2 arguments /, 'Too many arguments');

eval { my $x = AI::ExpertSystem::Simple::Goal->new(undef, 'message'); };
like($@, qr/^Goal->new\(\) argument 1 \(NAME\) is undefined /, 'Name is undefined');

eval { my $x = AI::ExpertSystem::Simple::Goal->new('fred', undef); };
like($@, qr/^Goal->new\(\) argument 2 \(MESSAGE\) is undefined /, 'Message is undefined');

################################################################################
# Create a AI::ExpertSystem::Simple::Goal correctly
################################################################################

my $x = AI::ExpertSystem::Simple::Goal->new('fred', 'this is the fred');
isa_ok($x, 'AI::ExpertSystem::Simple::Goal');

################################################################################
# Check that the name is recalled
################################################################################

eval { $x->name('fred'); };
like($@, qr/^Goal->name\(\) takes no arguments /, 'Too many arguments');

is($x->name(), 'fred', 'Remember our name');

################################################################################
# Check the goal
################################################################################

eval { $x->is_goal(); };
like($@, qr/^Goal->is_goal\(\) takes 1 argument /, 'Too few arguments');

eval { $x->is_goal(1, 2); };
like($@, qr/^Goal->is_goal\(\) takes 1 argument /, 'Too many arguments');

eval { $x->is_goal(undef); };
like($@, qr/^Goal->is_goal\(\) argument 1 \(NAME\) is undefined /, 'name is undefined');

is($x->is_goal('fred'), '1', 'Matches the goal');
is($x->is_goal('tom'), '', 'Does not matches the goal');

################################################################################
# Check the goal
################################################################################

eval { $x->answer(); };
like($@, qr/^Goal->answer\(\) takes 1 argument /, 'Too few arguments');

eval { $x->answer(1, 2); };
like($@, qr/^Goal->answer\(\) takes 1 argument /, 'Too many arguments');

eval { $x->answer(undef); };
like($@, qr/^Goal->answer\(\) argument 1 \(VALUE\) is undefined /, 'Value is undefined');

is($x->answer('banana'), 'this is the banana', 'Get the answer');
