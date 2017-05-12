#/usr/bin/env perl

use strict;
use warnings;

use AnyEvent;
use AnyEvent::Stomper;

my $stomper = AnyEvent::Stomper->new(
  host     => 'localhost',
  port     => '61613',
  login    => 'guest',
  passcode => 'guest',

  on_connect => sub {
    print "Connected to server\n";
  },

  on_disconnect => sub {
    print "Disconnected from server\n";
  },
);

my $cv     = AE::cv;
my $sub_id = 'foo';
my $dst    = '/queue/foo';

$stomper->subscribe(
  id          => $sub_id,
  destination => $dst,

  on_receipt => sub {
    my $err = $_[1];

    if ( defined $err ) {
      warn $err->message . "\n";
      $cv->send;

      return;
    }

    print "Subscribed to $sub_id\n";

    $stomper->send(
      destination => $dst,
      persistent  => 'true',
      body        => 'Hello, world!',
    );
  },

  on_message => sub {
    my $msg = shift;

    my $headers = $msg->headers;
    my $body    = $msg->body;

    print "Consumed: $body\n";

    $cv->send;
  }
);

$cv->recv;

$stomper->force_disconnect;
