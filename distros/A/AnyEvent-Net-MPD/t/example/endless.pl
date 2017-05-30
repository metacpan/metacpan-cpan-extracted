#!/usr/bin/env perl

use strict;
use warnings;

use List::Util qw( shuffle );
use Array::Utils qw( array_minus );
use AnyEvent;
use AnyEvent::Net::MPD;
use PerlX::Maybe;

my $mpd = AnyEvent::Net::MPD->new(
  maybe host => $ARGV[0],
  auto_connect => 1,
);

# use Log::Any::Adapter;
# Log::Any::Adapter->set('Stderr');

my $total_length = 21;
my $n = 1;
my $previous = -1;

my $idle; $idle = sub {
  $mpd->send( 'status', sub {
    my $status = shift->recv;

    my $current = $status->{songid};
    if ($current ne $previous) {
      $previous = $current;

      $mpd->send( 'playlist', sub {
        my @playlist = @{shift->recv};

        # I wish there was a smarter way
        $mpd->send( { parser => 'none' }, 'list_all', sub {
          my @files =
            map { (split /:\s+/, $_, 2)[1] }
            grep { /^file:/ }
            @{shift->recv};

          my $all_new = 1;
          my @new;
          foreach my $try (0..100) {
            my @indeces = shuffle( 0..$#files );
            @new = @files[ @indeces[ 0 .. $n-1 ] ];

            my @diff = array_minus( @new, @playlist );
            if (scalar @diff eq $n) { last }
            else { $all_new = 0 }
          }

          warn 'Some of the added songs already exist in the playlist!'
            unless $all_new;

          my $end = scalar @playlist;
          my @commands = map { [ addid => $_, $end++ ] } @new;
          push @commands, [ delete => "0:$n" ];

          $mpd->send( \@commands , sub {
            $mpd->send( idle => 'player' , $idle );
          });
        });
      });
    }
    else {
      $mpd->send( idle => 'player' , $idle );
    }
  });
};

$mpd->send( idle => 'player', $idle );

AnyEvent->condvar->recv;
