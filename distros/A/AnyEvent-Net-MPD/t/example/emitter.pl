#!/usr/bin/env perl

use strict;
use warnings;

use AnyEvent::Net::MPD;

use Log::Any::Adapter;
Log::Any::Adapter->set( 'Stderr', log_level => 'trace' );

my $mpd = AnyEvent::Net::MPD->new(
  maybe host => $ARGV[0],
  auto_connect => 1,
);

$mpd->on( error => sub { $mpd->noidle });

foreach my $event (qw(
    database udpate stored_playlist playlist player
    mixer output sticker subscription message
  )) {

  $mpd->on( $event => sub {
    print "$event changed\n";
  });
}

$mpd->idle->recv;
