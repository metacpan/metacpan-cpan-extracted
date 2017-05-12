#!/usr/bin/perl
#
# Copyright (C) 2011 by Mark Hindess

use strict;
use constant {
  DEBUG => $ENV{ANYEVENT_MQTT_TEST_DEBUG}
};
use Net::MQTT::Constants;
use Scalar::Util qw/weaken/;

$|=1;

BEGIN {
  require Test::More;
  $ENV{PERL_ANYEVENT_MODEL} = 'Perl' unless ($ENV{PERL_ANYEVENT_MODEL});
  eval { require AnyEvent; import AnyEvent;
         require AnyEvent::Socket; import AnyEvent::Socket };
  if ($@) {
    import Test::More skip_all => 'No AnyEvent::Socket module installed: $@';
  }
  eval { require AnyEvent::MockTCPServer; import AnyEvent::MockTCPServer };
  if ($@) {
    import Test::More skip_all => 'No AnyEvent::MockTCPServer module: '.$@;
  }
  import Test::More;
  use t::Helpers qw/test_error/;
}

my @connections = ( [] ); # just close

my $server;
eval { $server = AnyEvent::MockTCPServer->new(connections => \@connections); };
plan skip_all => "Failed to create dummy server: $@" if ($@);

my ($host, $port) = $server->connect_address;

plan tests => 9;

use_ok('AnyEvent::MQTT');

my $cv;
my $mqtt =
  AnyEvent::MQTT->new(host => $host, port => $port, client_id => 'acme_mqtt',
                      on_error => sub { $cv->send(@_) });

ok($mqtt, 'instantiate AnyEvent::MQTT object for eof test');
$cv = $mqtt->connect();
my ($fatal, $error) = $cv->recv;
is($fatal, 1, '... fatal error');
is($error, 'EOF', '... message');

is(test_error(sub { $mqtt->subscribe }),
   'AnyEvent::MQTT->subscribe requires "topic" parameter',
   'subscribe w/o topic');

is(test_error(sub { $mqtt->unsubscribe }),
   'AnyEvent::MQTT->unsubscribe requires "topic" parameter',
   'unsubscribe w/o topic');

is(test_error(sub { $mqtt->subscribe(topic => '/test') }),
   'AnyEvent::MQTT->subscribe requires "callback" parameter',
   'subscribe w/o callback');

is(test_error(sub { $mqtt->publish }),
   'AnyEvent::MQTT->publish requires "topic" parameter',
   'publish w/o topic');

is(test_error(sub { $mqtt->publish(topic => '/test') }),
   'AnyEvent::MQTT->publish requires "message" or "handle" parameter',
   'publish w/o message or handle');
