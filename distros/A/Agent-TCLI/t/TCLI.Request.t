#!/usr/bin/env perl
# $Id: TCLI.Request.t 62 2007-05-03 15:55:17Z hacker $

use Test::More tests => 48;
use lib 'blib/lib';

# TASK Test suite is not complete. Need testing for catching errors.

use_ok('Agent::TCLI::Request');
use warnings;
use strict;
use POE;

my $test1 = Agent::TCLI::Request->new({
					'id'		=> 1,
					'args'		=> ['one', 'two', 'three', ],
					'command'	=> ['testing', ],
					'sender'	=> 'Control',
					'postback'	=> 'TestResponse',
					'input'		=> 'testing one two three',
});


is(ref($test1),'Agent::TCLI::Request','new test1 object with args');

my $test2 = Agent::TCLI::Request->new();
is(ref($test2),'Agent::TCLI::Request', 'new test2 object no args' );

# Test id get-set methods
is($test1->id,1, '$test1->id get from init args');

ok($test2->id(2),'$test2->id set ');
is($test2->id,2, '$test2->id get from set');

# Test sender accessor/mutator methods
is($test1->sender->[0],'Control', '$test1->sender from init args');
# for init 'sender'		=> 'Control',
ok($test2->sender(['transport_xmpp','transport_test']),'$test2->sender init mutator');
is_deeply($test2->sender,['transport_xmpp','transport_test'], '$test2->sender accessor');

# Test postback accessor/mutator methods
is($test1->postback->[0],'TestResponse', '$test1->postback from init args');
# for init 'postback'		=> 'TestResponse',
ok($test2->postback(['test@example.com/test','test-master']),'$test2->postback init mutator');
is_deeply($test2->postback,['test@example.com/test','test-master'], '$test2->postback accessor');

# Test args get-set methods
is_deeply($test1->args,['one', 'two', 'three', ], '$test1->get_args get from init args');

ok($test2->args(['one'] ),'$test2->set_args set ');
is_deeply($test2->args,['one'] , '$test2->get_args from set');

# test automethods for args array
is($test1->shift_args,'one', '$test1->shift_args ');
is_deeply($test1->args,[ 'two', 'three', ], '$test1->args after shift');

is($test1->pop_args,'three', '$test1->pop_args ');
is_deeply($test1->args,[ 'two', ], '$test1->args after pop');

ok($test1->unshift_args('one'), '$test1->unshift_args ');
is_deeply($test1->args,['one', 'two',  ], '$test1->args after unshift');

ok($test1->push_args('three'), '$test1->push_args ');
is_deeply($test1->args,['one', 'two', 'three', ], '$test1->args after push');

ok($test1->push_args('four'), '$test1->push_args ');
is_deeply($test1->args,['one', 'two', 'three', 'four', ], '$test1->args after push');

is($test1->depth_args,4, '$test1->depth_args ');

# General Automethod tests

ok($test1->set_test('test'),'$test1->set_test');
is($test1->get_test,'test','$test1->get_test');

ok($test1->set_myarray(['one'] ),'$test1->set_myarray autoload ');
is_deeply($test1->get_myarray,['one'] , '$test1->get_myarray  autoload');

ok($test1->push_myarray('two','three'), '$test1->push_myarray ');
is_deeply($test1->get_myarray,['one', 'two', 'three', ], '$test1->get_myarray ');

ok($test1->push_myarray('four'), '$test1->push_myarray ');
is_deeply($test1->get_myarray,['one', 'two', 'three', 'four', ], '$test1->get_myarray');
is($test1->depth_myarray,4, '$test1->depth_myarray ');

is($test1->shift_myarray(),'one','$test1->shift_myarray ');
is_deeply($test1->get_myarray,[ 'two', 'three', 'four', ], '$test1->get_myarray');
is($test1->depth_myarray,3, '$test1->depth_myarray ');
is($test1->print_myarray,'two three four', '$test1->print_myarray');

ok($test1->unshift_myarray('one'), '$test1->unshift_myarray ');
is_deeply($test1->get_myarray,['one', 'two', 'three', 'four', ], '$test1->get_myarray');
is($test1->depth_myarray,4, '$test1->depth_myarray ');

#MakeResponse

my $resp2 = $test2->MakeResponse("test", 200);

is_deeply($resp2->sender,['transport_xmpp','transport_test'], '$resp2->sender accessor');
is_deeply($resp2->postback,['test@example.com/test','test-master'], '$resp2->postback accessor');

is($resp2->shift_sender,'transport_xmpp','shift sender');
is($resp2->shift_postback,'test@example.com/test','shift postback');

# Did the original arrays not change.
is_deeply($test2->sender,['transport_xmpp','transport_test'], '$test2->sender accessor');
is_deeply($test2->postback,['test@example.com/test','test-master'], '$test2->postback accessor');
