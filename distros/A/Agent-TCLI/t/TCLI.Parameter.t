#!/usr/bin/env perl
# $Id: TCLI.Parameter.t 48 2007-04-11 12:43:07Z hacker $

use Test::More qw(no_plan);
use lib 'blib/lib';
use warnings;
use strict;

# TASK Test suite is not complete. Need more testing for catching errors.
BEGIN {
    use_ok('Agent::TCLI::Parameter');
}

my $test1 = Agent::TCLI::Parameter->new(
    name 		=> 'test1',
    aliases 	=> 't1',
    constraints => ['ASCII'],
    help 		=> "text for a parameter",
    manual 		=>
    	'This parameter is used for testing the module.',
    type 		=> 'Param',
    default		=> 'text',
    class		=> 'Test::Test',
    show_method	=> 'print',
    cl_option	=> '-t'
);

my $test2 = Agent::TCLI::Parameter->new(
#    name 		=> 'test2',
#    aliases 	=> 'i1',
#    constraints => ['INT'],
#    help 		=> "int for a parameter",
#    manual 		=>
#    	'This parameter is used for testing the module.',
#    type 		=> 'Param',
#    default		=> 42,
#    class		=> 'Test::Test',
#    show_method	=> 'print',
#    cl_option	=> '-i'
);

is(ref($test1),'Agent::TCLI::Parameter','new test1 object');
is(ref($test2),'Agent::TCLI::Parameter','new test2 object');

# Test name accessor-mutator methods
is($test1->name,'test1', '$test1->name accessor from init args');
ok($test2->name('test2'),'$test2->name mutator ');
is($test2->name,'test2', '$test2->name accessor from mutator');

# Test aliases accessor/mutator methods
is($test1->aliases,'t1', '$test1->aliases from init args');
ok($test2->aliases('i1'),'$test2->aliases init mutator');
is($test2->aliases,'i1', '$test2->aliases accessor');

# Test constraints accessor/mutator methods
is_deeply($test1->constraints,['ASCII'], '$test1->constraints from init args');
ok($test2->constraints(['INT']),'$test2->constraints init mutator');
is_deeply($test2->constraints,['INT'], '$test2->constraints accessor');

# Test help accessor/mutator methods
is($test1->help,'text for a parameter', '$test1->help from init args');
ok($test2->help('int for a parameter'),'$test2->help init mutator ');
is($test2->help,'int for a parameter', '$test2->help accessor');

# Test manual accessor/mutator methods
is($test1->manual,'This parameter is used for testing the module.', '$test1->manual from init args');
# for init 'manual'		=> 'This parameter is used for testing the module.',
ok($test2->manual('This parameter is used for testing the module.'),'$test2->manual init mutator');
is($test2->manual,'This parameter is used for testing the module.', '$test2->manual accessor');

# Test type accessor/mutator methods
is($test1->type,'Param', '$test1->type from init args');
# for init 'type'		=> 'Param',
ok($test2->type('Param'),'$test2->type init mutator');
is($test2->type,'Param', '$test2->type accessor');

# Test default accessor/mutator methods
is($test1->default,'text', '$test1->default from init args');
# for init 'default'		=> 'text',
ok($test2->default(42),'$test2->default init mutator');
is($test2->default,42, '$test2->default accessor');

# Test class accessor/mutator methods
is($test1->class,'Test::Test', '$test1->class from init args');
# for init 'class'		=> 'Test::Test',
ok($test2->class('Test::Test'),'$test2->class init mutator');
is($test2->class,'Test::Test', '$test2->class accessor');

# Test show_method accessor/mutator methods
is($test1->show_method,'print', '$test1->show_method from init args');
# for init 'show_method'		=> 'print',
ok($test2->show_method('print'),'$test2->show_method init mutator');
is($test2->show_method,'print', '$test2->show_method accessor');

# Test cl_option accessor/mutator methods
is($test1->cl_option,'-t', '$test1->cl_option from init args');
# for init 'cl_option'		=> 't1',
ok($test2->cl_option('-i'),'$test2->cl_option init mutator');
is($test2->cl_option,'-i', '$test2->cl_option accessor');

my $verbose = Agent::TCLI::Parameter->new(
    name 		=> 'test_verbose',
    aliases 	=> 'verbose|v',
    constraints => ['UINT'],
    help 		=> "an integer for verbosity",
    manual 		=>
    	'This debugging parameter can be used to adjust the verbose setting',
    type 		=> 'Counter',
    cl_option	=> '-v',
);

my $switch = Agent::TCLI::Parameter->new(
    name 		=> 'switch',
    help 		=> "a switch for a parameter",
    manual 		=>
    	'This parameter is used for testing the module.',
    type 		=> 'Switch',
    cl_option	=> '-s',
);

# Method Alias
is($test1->Alias,'test1|t1','$test1->Alias');
is($test2->Alias,'test2|i1','$test2->Alias');
is($verbose->Alias,'test_verbose|verbose|v','$verbose->Alias has multiple ');
is($switch->Alias,'switch','$switch->Alias has none');

# Method BuildCommandParam

my %param1 = (
	test1 			=> 'some text',
	test2 			=> 43,
	test_verbose 	=> 1,
	switch			=> 1,
);

is($test1->BuildCommandParam(\%param1),'-t "some text"', 'BuildCommandParam with quotes');
is($test2->BuildCommandParam(\%param1),'-i 43', 'BuildCommandParam Param');
is($verbose->BuildCommandParam(\%param1),'-v', 'BuildCommandParam Counter');
is($switch->BuildCommandParam(\%param1),'-s', 'BuildCommandParam switch');

%param1 = (
	test1 			=> 'sometext',
	test_verbose 	=> 3,
	switch			=> 0,
);

is($test1->BuildCommandParam(\%param1),'-t sometext', 'BuildCommandParam with no quotes');
is($test2->BuildCommandParam(\%param1),'', 'BuildCommandParam empty Param');
is($verbose->BuildCommandParam(\%param1),'-v -v -v', 'BuildCommandParam multiple Counter');
is($switch->BuildCommandParam(\%param1),'', 'BuildCommandParam empty switch');

%param1 = (
	test_verbose 	=> 0,
);

is($verbose->BuildCommandParam(\%param1),'', 'BuildCommandParam zero Counter');
