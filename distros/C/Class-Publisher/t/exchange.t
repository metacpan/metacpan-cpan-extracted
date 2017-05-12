#!/usr/local/bin/perl -w
# $Id: exchange.t,v 1.2 2005/03/25 13:20:21 simonflack Exp $
# Description: Basic integration test

use Test::More tests => 20;
use strict;
use lib 't';

my $test_class = 'Class::Publisher';
require_ok($test_class);
require_ok('Telephone');

#require Log::Trace;
#import Log::Trace print => {Deep => 1, Match => qr/Class::Publisher/};

my $exchange = new Telephone::Exchange;
my $test_phone = new Telephone('0123 555 0000');
ok(!$test_phone->online(), 'new phone: not online - exchange not initialised');

# Subscribe exchange to Telephone class events
my $rv = Telephone->add_subscriber('connect' => $exchange, 'register_phone');
is($rv, 1, 'Telephone::Exchange subscribed to Telephone "connect" event');

$rv = Telephone->add_subscriber('disconnect' => $exchange, 'unregister_phone');
is($rv, 1, 'Telephone::Exchange subscribed to Telephone "disconnect" event');

$rv = Telephone->add_subscriber('call' => $exchange, 'connect_phones');
is($rv, 1, 'Telephone::Exchange subscribed to Telephone "call" event');

$rv = Telephone->add_subscriber('end_call' => $exchange, 'disconnect_phones');
is($rv, 1, 'Telephone::Exchange subscribed to Telephone "end_call" event');


# Switch the test phone on now the exchange is initialised
$test_phone->switch_on();
ok($test_phone->online(), 'phone now online - exchange is initialised');

# Create a new phone
my $friends_phone = new Telephone('0123 555 1111');
ok($friends_phone->online, 'new phone is online');

# Call a non existant phone number
$test_phone->call('0123 555 9999');
ok(!$test_phone->busy, 'call to non-existant number failed');
is($test_phone->{hangup}, 'WRONG NUMBER', 'exchange caught "call" event');

# Call the friend's phone
$test_phone->call($friends_phone->{number});
ok($test_phone->busy && $friends_phone->busy,
   'call connected between two phones');

# Try and call from another phone while still connected
my $home_phone = new Telephone('0123 555 5555');
$home_phone->call($test_phone->{number});
ok(!$home_phone->busy && $home_phone->{hangup} eq 'BUSY',
   'cannot call a phone that is engaged');

# say something
$test_phone->speak('Wazzzup!');
is($friends_phone->{listened_to}[-1], 'Wazzzup!',
   'friends phone caught communicate event');
$friends_phone->speak('Who is this?');
is($test_phone->{listened_to}[-1], 'Who is this?',
   'test phone caught communicate response');
$test_phone->speak('Err. I think I have the wrong number');
$friends_phone->speak('Bye then!');

# Hang up
$friends_phone->hangup();
ok(!$test_phone->busy && !$friends_phone->busy, 'both phones hung up');

# Check subscription cancelled
ok(!$test_phone->get_subscribers('communicate'),
   'test phone has no "communicate" subscribers');
ok(!$friends_phone->get_subscribers('communicate'),
   'other phone has no "communicate" subscribers');

ok($exchange->valid_phone($friends_phone));
$friends_phone->switch_off;
ok(!$exchange->valid_phone($friends_phone), 'exchange caught disconnect event');
