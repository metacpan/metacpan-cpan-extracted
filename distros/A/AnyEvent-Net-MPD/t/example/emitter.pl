#!/usr/bin/env perl

use strict;
use warnings;

use AnyEvent::Net::MPD;
Log::Any::Adapter->set( 'Stderr', log_level => 'trace' );
my $log = Log::Any->get_logger;

my $mpd = AnyEvent::Net::MPD->new(
  maybe host => $ARGV[0],
  auto_connect => 1,
);

foreach my $event (qw(
    database udpate stored_playlist playlist player
    mixer output sticker subscription message
  )) {

  $mpd->on( $event => sub {
    print "$event changed\n";
  });
}

$mpd->idle->recv;
