#/usr/bin/env perl

use strict;
use warnings;

use AnyEvent;
use AnyEvent::Stomper;

my $stomper = AnyEvent::Stomper->new(
  host      => 'localhost',
  port      => '61613',
  login     => 'guest',
  passcode  => 'guest',
  heartbeat => [ 5000, 5000 ],

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
  ack         => 'client-individual',

  on_receipt => sub {
    my $receipt = shift;
    my $err     = shift;

    if ( defined $err ) {
      warn $err->message . "\n";
      $cv->send;

      return;
    }

    print "Subscribed to $sub_id\n";
  },

  on_message => sub {
    my $msg = shift;

    my $headers = $msg->headers;
    my $body    = $msg->body;

    print "Consumed: $body\n";

    $stomper->ack(
      message => $msg,
      receipt => 'auto',

      sub {
        my $receipt = shift;
        my $err     = shift;

        if ( defined $err ) {
          warn $err->message . "\n";
          return;
        }

        print "Acked: $headers->{'message-id'}\n";
      }
    );
  }
);

my $on_signal = sub {
  print "Stopped\n";

  $stomper->unsubscribe(
    id          => $sub_id,
    destination => $dst,

    sub {
      my $receipt = shift;
      my $err     = shift;

      if ( defined $err ) {
        warn $err->message . "\n";
        $cv->send;

        return;
      }

      print "Unsubscribed from $sub_id\n";


      $cv->send;
    }
  );
};

my $int_w  = AE::signal( INT  => $on_signal );
my $term_w = AE::signal( TERM => $on_signal );

$cv->recv;

$stomper->force_disconnect;
