#!/usr/bin/env perl
# $Id: TCLI.Command.GetoptLucid.t 57 2007-04-30 11:07:22Z hacker $

use Test::More tests => 36;
use Agent::TCLI::Parameter;
use Agent::TCLI::Request;
use Getopt::Lucid;
use POE;

use Data::Dump qw(pp);

# TASK Test suite is not complete. Need testing for catching errors.
BEGIN {
    use_ok('Agent::TCLI::Command');
}

my $request = Agent::TCLI::Request->new({
					'id'		=> 1,
					'args'		=> ['paramint', '7', 'verbose', ],
					'command'	=> ['testing', ],
					'sender'	=> 'Control',
					'postback'	=> 'TestResponse',
					'input'		=> 'testing paramint 7 verbose',
});


my $verbose = Agent::TCLI::Parameter->new(
    constraints => ['UINT'],
    help => "an integer for verbosity",
    manual => 'This debugging parameter can be used to adjust the verbose setting for the XMPP transport.',
    name => 'test_verbose',
    aliases => 'verbose|v',
    type => 'Counter',
);

my $paramint = Agent::TCLI::Parameter->new(
    constraints => ['UINT'],
    help => "an integer for a parameter",
    manual => 'This parameter is used to to test the Command package.',
    name => 'paramint',
    type => 'Param',
);

my $paramA = Agent::TCLI::Parameter->new(
    constraints	=> ['ASCII'],
    help 		=> "some text for a parameter",
    manual 		=> 'This parameter is used to to test the Command package.',
    name		=> 'paramA',
    type 		=> 'Param',
    default 	=> 'default',
);


my %cmd1 = (
	        'name'		=> 'cmd1',
	        'contexts'	=> {'/' => 'cmd1'},
    	    'help' 		=> 'cmd1 help',
        	'usage'		=> 'cmd1 usage',
        	'topic'		=> 'test',
        	'call_style'=> 'session',
        	'command'	=> 'test1',
	        'handler'	=> 'cmd1',
	        'parameters' => {
	        	'test_verbose' 	=> $verbose,
	        	'paramint'	=> $paramint,
	        	},
			'verbose' 	=> 0,
);
my %cmd2 = (
	        'name'		=> 'cmd2',
	        'contexts'	=> {'/' => 'cmd2'},
    	    'help' 		=> 'cmd2 help',
        	'usage'		=> 'cmd2 usage',
        	'topic'		=> 'test',
        	'call_style'=> 'state',
        	'command'	=> 'test2',
	        'handler'	=> 'cmd2',
	        'parameters' => {
	        	'test_verbose' 	=> $verbose,
	        	'paramA'	=> $paramA,
	        	},
			'verbose' 	=> 0,
);

#use warnings;
#use strict;

my $test1 = Agent::TCLI::Command->new(%cmd1);
my $test2 = Agent::TCLI::Command->new(%cmd2);

is(ref($test1),'Agent::TCLI::Command','new test1 object');
is(ref($test2),'Agent::TCLI::Command','new test2 object');

# Test name accessor-mutator methods
is($test1->name,'cmd1', '$test1->name accessor from init args');
ok($test2->name('cmd2'),'$test2->name mutator ');
is($test2->name,'cmd2', '$test2->name accessor from mutator');

# Test topic get-set methods
is($test1->topic,'test', '$test1->topic get from init args');
ok($test2->topic('test'),'$test2->topic set ');
is($test2->topic,'test', '$test2->topic get from set');

# Test help get-set methods
is($test1->help,'cmd1 help', '$test1->help get from init args');
ok($test2->help('cmd2 help'),'$test2->help set ');
is($test2->help,'cmd2 help', '$test2->help get from set');

# Test usage get-set methods
is($test1->usage,'cmd1 usage', '$test1->usage get from init args');
ok($test2->usage('cmd2 usage'),'$test2->usage set ');
is($test2->usage,'cmd2 usage', '$test2->usage get from set');

# Test call_style get-set methods
is($test1->call_style,'session', '$test1->call_style get from init args');
ok($test2->call_style('state'),'$test2->call_style set ');
is($test2->call_style,'state', '$test2->call_style get from set');

# Test command get-set methods
is($test1->command,'test1', '$test1->command get from init args');
ok($test2->command('test2'),'$test2->command set ');
is($test2->command,'test2', '$test2->command get from set');

# Test handler get-set methods
is($test1->handler,'cmd1', '$test1->handler get from init args');
ok($test2->handler('cmd2'),'$test2->handler set ');
is($test2->handler,'cmd2', '$test2->handler get from set');

# Test GetoptLucid
my $testee = "GetoptLucid";

$request->args([qw(paramint 7 verbose)]);

my $opt1 = $test1->GetoptLucid($poe_kernel, $request );

is($opt1->get_paramint,7,"$testee paramint ok");
is($opt1->get_test_verbose,1,"$testee verbose ok");

$request->args([qw(paramA AAAAA verbose)]);

my $opt2 = $test2->GetoptLucid($poe_kernel, $request );

is($opt2->get_paramA,'AAAAA',"$testee paramA ok");
is($opt2->get_test_verbose,1,"$testee verbose ok");

# Test Validator
my $testee = "Validator";

$request->args([qw(paramint 7 verbose)]);

$opt1 = $test1->Validate($poe_kernel, $request);

is($opt1->{'paramint'},7,"$testee paramint ok");
is($opt1->{'test_verbose'},1,"$testee verbose ok");

$request->args([qw(paramA AAAAA verbose)]);

$opt2 = $test2->Validate($poe_kernel, $request);

is($opt2->{'paramA'},'AAAAA',"$testee paramA ok");
is($opt2->{'test_verbose'},1,"$testee verbose ok");

# Validate with no args
$request->args([ ]);

$opt1 = $test1->Validate($poe_kernel, $request);

is($opt1->{'paramint'},undef,"$testee paramint ok");
is($opt1->{'test_verbose'},undef,"$testee verbose ok");

$request->args([ ]);

$opt2 = $test2->Validate($poe_kernel, $request);

# Can't test for defaults without a package, so this is still undef
is($opt2->{'paramA'},undef,"$testee paramA ok");
is($opt2->{'test_verbose'},undef,"$testee verbose ok");

