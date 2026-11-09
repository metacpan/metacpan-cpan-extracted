#!/usr/bin/env perl
# Minimal repro, no DBIO: Future::IO 0.23 built-in implementation.
# Cancelling a poll from the callback of a poll in front of it kills the round.
use strict;
use warnings;
use IO::Poll qw( POLLIN );
use Future;
use Future::IO;

pipe( my ( $r1, $w1 ) ) or die $!;
pipe( my ( $r2, $w2 ) ) or die $!;
syswrite $w1, 'x';
syswrite $w2, 'x';

my $first  = Future::IO->poll( $r1, POLLIN );
my $second = Future::IO->poll( $r2, POLLIN );

# the second poll is behind the first in the poller list; the first one's
# callback cancels it
$first->on_done( sub { $second->cancel } );

my $f = Future->wait_any( $first, Future::IO->sleep(5) );
my $ok = eval { $f->get; 1 };
print $ok ? "OK: round survived\n" : "DIED: $@";
exit( $ok ? 0 : 1 );
