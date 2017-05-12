#!/usr/bin/env perl
# $Id: TCLI.Command.t 57 2007-04-30 11:07:22Z hacker $

use Test::More qw(no_plan);
use lib 'blib/lib';

use Data::Dump qw(pp);

# TASK Test suite is not complete. Need testing for catching errors.
BEGIN {
    use_ok('Agent::TCLI::Command');
}

my %cmd1 = (
	        'name'		=> 'cmd1',
	        'contexts'	=> {'/' => 'cmd1'},
    	    'help' 		=> 'cmd1 help',
        	'usage'		=> 'cmd1 usage',
        	'topic'		=> 'test',
        	'call_style'=> 'session',
        	'command'	=> 'test1',
	        'handler'	=> 'cmd1',

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


#$rc1 = $test1->RawCommand;
#$rc2 = $test2->RawCommand;
#
#is_deeply($rc1,\%cmd1,'$test1->RawCommand');
#is_deeply($rc2,\%cmd2,'$test1->RawCommand');

#print "rc1".pp($rc1);
#print "cmd1".pp(\%cmd1);
#print "rc2".pp($rc2);
