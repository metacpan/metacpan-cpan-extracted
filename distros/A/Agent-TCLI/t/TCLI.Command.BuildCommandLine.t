#!/usr/bin/env perl
# $Id: TCLI.Command.BuildCommandLine.t 48 2007-04-11 12:43:07Z hacker $

use warnings;
use strict;

use Test::More tests => 13;
use Agent::TCLI::Parameter;
#use Agent::TCLI::Request;
#use Getopt::Lucid;
#use POE;
#
#use Data::Dump qw(pp);

# TASK Test suite is not complete. Need more testing for catching errors.
BEGIN {
    use_ok('Agent::TCLI::Command');
}


my $text1 = Agent::TCLI::Parameter->new(
    name 		=> 'text1',
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

my $int1 = Agent::TCLI::Parameter->new(
    name 		=> 'int1',
    aliases 	=> 'i1',
    constraints => ['INT'],
    help 		=> "int for a parameter",
    manual 		=>
    	'This parameter is used for testing the module.',
    type 		=> 'Param',
    default		=> 42,
    class		=> 'Test::Test',
    show_method	=> 'print',
    cl_option	=> '-i'
);

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

my $test1 = Agent::TCLI::Command->new(
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
	        	'text1'			=> $text1,
	        	'int1'			=> $int1,
	        	'switch'		=> $switch,
	        	},
			'verbose' 	=> 0,
);

my $test2 = Agent::TCLI::Command->new(
	        'name'		=> 'cmd2',
	        'contexts'	=> {'/' => 'cmd2'},
    	    'help' 		=> 'cmd2 help',
        	'usage'		=> 'cmd2 usage',
        	'topic'		=> 'test',
        	'call_style'=> 'session',
        	'command'	=> 'test2',
	        'handler'	=> 'cmd2',
	        'cl_options' => '--req',
	        'parameters' => {
	        	'test_verbose' 	=> $verbose,
	        	'text1'			=> $text1,
	        	'int1'			=> $int1,
	        	'switch'		=> $switch,
	        	},
			'verbose' 	=> 0,
);


# Method BuildCommandLine

my %param1 = (
	text1 			=> 'some text',
	int1 			=> 43,
	test_verbose 	=> 1,
	switch			=> 1,
);

is($test1->BuildCommandLine(\%param1,1),'test1 -i 43 -s -v -t "some text"', 'BuildCommandLine with cmd, quotes');
is($test1->BuildCommandLine(\%param1),'-i 43 -s -v -t "some text"', 'BuildCommandLine no cmd, quotes');
is($test2->BuildCommandLine(\%param1,1),'test2 --req -i 43 -s -v -t "some text"', 'BuildCommandLine2 with cmd, quotes');
is($test2->BuildCommandLine(\%param1),'--req -i 43 -s -v -t "some text"', 'BuildCommandLine2 no cmd, quotes');

%param1 = (
	text1 			=> 'sometext',
	test_verbose 	=> 3,
	switch			=> 0,
);

is($test1->BuildCommandLine(\%param1,1),'test1 -v -v -v -t sometext', 'BuildCommandLine with cmd, no quotes, multiple counter');
is($test1->BuildCommandLine(\%param1),'-v -v -v -t sometext', 'BuildCommandLine no cmd, no quotes, multiple counter');
is($test2->BuildCommandLine(\%param1,1),'test2 --req -v -v -v -t sometext', 'BuildCommandLine2 with cmd, no quotes, multiple counter');
is($test2->BuildCommandLine(\%param1),'--req -v -v -v -t sometext', 'BuildCommandLine2 no cmd, no quotes, multiple counter');

%param1 = (
	test_verbose 	=> 0,
);

is($test1->BuildCommandLine(\%param1,1),'test1', 'BuildCommandLine with cmd zero Counter, nothing else');
is($test1->BuildCommandLine(\%param1),'', 'BuildCommandLine no cmd zero Counter, nothing else');
is($test2->BuildCommandLine(\%param1,1),'test2 --req', 'BuildCommandLine2 with cmd zero Counter, nothing else');
is($test2->BuildCommandLine(\%param1),'--req', 'BuildCommandLine2 no cmd zero Counter, nothing else');
