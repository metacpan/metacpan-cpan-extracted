#!/usr/bin/env perl

use strict;
use warnings;

use AnyEvent::Net::MPD;
use Term::ReadLine;
use PerlX::Maybe;
use Data::Printer output => 'stdout';

my $mpd = AnyEvent::Net::MPD->new(
  maybe host => $ARGV[0],
  auto_connect => 1,
);

print "Connected to MPD (v", $mpd->version, ")\n";
my $prompt = "# ";

my $term = Term::ReadLine->new('MPD REPL');
my $OUT = $term->OUT || \*STDOUT;

while ( defined ($_ = $term->readline($prompt)) ) {
  my $cmd = $_;
  my $cv = $mpd->send( $cmd, sub {
    my $res = shift->recv;
    my $has_data =
        ( ref $res eq 'ARRAY' ) ? scalar @{$res}
      : ( ref $res eq 'HASH' )  ? keys   %{$res}
      : $res;

    p $res if !$@ and $has_data;
    $term->addhistory($cmd) if /\S/;
  });

  $cv->recv;
}
