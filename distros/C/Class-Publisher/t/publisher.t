#!/usr/local/bin/perl -w
# $Id: publisher.t,v 1.3 2005/03/25 13:20:21 simonflack Exp $
# Description: API test

use Test::More tests => 22;
use strict;

require_ok('Class::Publisher');
#require Log::Trace;
#import Log::Trace print => {Deep => 1, Match => qr/Class::Publisher/};

package Mini_Publisher;
@Mini_Publisher::ISA = 'Class::Publisher';
sub new { bless {}, shift }

package main;
my ($rv, @s, %event);

# Catch errors
eval {Mini_Publisher->add_subscriber()};
ok($@, 'add_subscriber requires params');

eval {Mini_Publisher->add_subscriber('test', [])};
ok($@, 'subscriber reference should be a blessed object');

eval {Mini_Publisher->add_subscriber('test', '')};
ok($@, 'subscriber cant be empty string');

# Test class subscription
sub catch_all        { $event{all}++ }
sub catch_specific   { $event{specific}++ }
sub update           { $event{update}++ }
sub catch_all_again  {}
sub catch_all_object {}

$rv = Mini_Publisher->add_subscriber(undef, \&catch_all);
is ($rv, 1, 'class->add_subscriber(undef, \&code)');
@s = Mini_Publisher->get_subscribers();
is_deeply (\@s, [\&catch_all], 'class->get_subscribers()');

$rv = Mini_Publisher->add_subscriber('*', \&catch_all_again);
is ($rv, 2, 'class->add_subscriber("*", \&code)');
@s = Mini_Publisher->get_subscribers('*');
is_deeply ([sort @s], [sort \&catch_all, \&catch_all_again],
           'class->get_subscribers("*")');

$rv = Mini_Publisher->delete_subscriber('*', \&catch_all_again);
is ($rv, 1, 'class->delete_subscriber(undef, \&code)');
@s = Mini_Publisher->get_subscribers();

# Test object subscription
my $pub = Mini_Publisher->new();
$rv = $pub->add_subscriber('*', \&catch_all_object);
is ($rv, 1, 'object->add_subscriber("*", \&code)');

@s = $pub->get_subscribers();
ok(@s == 2, 'object->get_subscribers("*") inherits class subscribers');

@s = Mini_Publisher->get_subscribers();
ok(@s == 1, 'class->get_subscribers("*") donesnt inherit object subscribers');

# Test inheritance
@Mini_Publisher2::ISA = 'Mini_Publisher';
@s = Mini_Publisher2->get_subscribers();
ok(@s == 1, 'subclass->get_subscribers("*") inherit parent class subscribers');


# Test specific events
Mini_Publisher->add_subscriber('specific_event', \&catch_specific);
@s = Mini_Publisher->get_subscribers();
ok(@s == 2, 'subclass->get_subscribers("*") returns specific events too');
@s = Mini_Publisher->get_subscribers('specific_event');
ok(@s == 1, 'subclass->get_subscribers("specific_event") does just that');

# Test Class subcription
$rv = Mini_Publisher->add_subscriber('specific_event', 'main');
is ($rv, 2, 'class->add_subscriber("specific_event", Class)');

Mini_Publisher->notify_subscribers('specific_event');
is_deeply(\%event, {all => 1, specific => 1, update => 1},
          'class->notify_subscribers(specific_event) notified "*" as well');

# Test object subscription
package Mini_Subscriber;
sub new { bless {}, shift };
sub update {shift->{update}++};
sub custom_update {shift->{custom_update}++};
package main;

my $subscriber = new Mini_Subscriber;
$rv = Mini_Publisher->add_subscriber('custom_event', $subscriber);
is ($rv, 1, 'class->add_subscriber("specific_event", object)');

Mini_Publisher->notify_subscribers('custom_event');
is($subscriber->{update}, 1, 'object subscriber notified via object->update');

# Test object with custom method
$rv = Mini_Publisher->add_subscriber('custom_event', $subscriber, 'custom_update');
is ($rv, 1, 'object subscriber with custom method');

Mini_Publisher->notify_subscribers('custom_event');
is($subscriber->{custom_update}, 1, 'object subscriber notified via custom method');

is($subscriber->{update}, 1, 'object is subscriber, not object/method combo');

