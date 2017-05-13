#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 28;

use_ok('AI::ExpertSystem::Simple');

################################################################################
# Create a new expert system
################################################################################

my $x;

eval { $x = AI::ExpertSystem::Simple->new(1); };
like($@, qr/^Simple->new\(\) takes no arguments /, 'Too many arguments');

$x = AI::ExpertSystem::Simple->new();

isa_ok($x, 'AI::ExpertSystem::Simple');

################################################################################
# Load a file
################################################################################

eval { $x->load(); };
like($@, qr/^Simple->load\(\) takes 1 argument /, 'Too few arguments');

eval { $x->load(1,2); };
like($@, qr/^Simple->load\(\) takes 1 argument /, 'Too many arguments');

eval { $x->load(undef); };
like($@, qr/^Simple->load\(\) argument 1 \(FILENAME\) is undefined /, 'Filename is undefined');

eval { $x->load('no_test.xml'); };
like($@, qr/^Simple->load\(\) unable to use file /, 'Cant use this file');

eval { $x->load('t/empty.xml'); };
like($@, qr/^Simple->load\(\) XML parse failed: /, 'Cant use this file');

is($x->load('t/test.xml'), '1', 'File is loaded');

eval { $x->process(1); };
like($@, qr/^Simple->process\(\) takes no arguments /, 'Too many arguments');

is($x->process(), 'question', 'We have a question to answer');

eval { $x->get_question(1); };
like($@, qr/^Simple->get_question\(\) takes no arguments /, 'Too many arguments');

my ($t, $r) = $x->get_question();

eval { $x->answer(); };
like($@, qr/^Simple->answer\(\) takes 1 argument /, 'Too few arguments');

eval { $x->answer(1,2); };
like($@, qr/^Simple->answer\(\) takes 1 argument /, 'Too many arguments');

eval { $x->answer(undef); };
like($@, qr/^Simple->answer\(\) argument 1 \(VALUE\) is undefined /, 'Value is undefined');

$x->answer('yes');

is($x->process(), 'continue', 'Carry on');
is($x->process(), 'finished', 'Thats all folks');

eval { $x->get_answer(1); };
like($@, qr/^Simple->get_answer\(\) takes no arguments /, 'Too many arguments');

is($x->get_answer(), 'You have set the goal to pretzel', 'Got the answer');

################################################################################
# Reset and do it all again
################################################################################

eval { $x->reset(1); };
like($@, qr/^Simple->reset\(\) takes no arguments /, 'Too many arguments');

$x->reset();

is($x->process(), 'question', 'We have a question to answer');

($t, $r) = $x->get_question();

$x->answer('yes');

is($x->process(), 'continue', 'Carry on');
is($x->process(), 'finished', 'Thats all folks');

is($x->get_answer(), 'You have set the goal to pretzel', 'Got the answer');

my @log = $x->log();

isnt(scalar @log, 0, 'The log has data');

@log = $x->log();

is(scalar @log, 0, 'The log is empty');

eval { $x->explain(1); };
like($@, qr/^Simple->explain\(\) takes no arguments /, 'Too many arguments');

$x->explain();
@log = $x->log();

isnt(scalar @log, 0, 'The log has data');
