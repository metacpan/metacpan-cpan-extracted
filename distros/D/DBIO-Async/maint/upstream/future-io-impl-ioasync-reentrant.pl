#!/usr/bin/env perl
# Minimal repro, no DBIO: Future::IO::Impl::IOAsync 0.805 (IO-Async dist).
# The on_read_ready handler is not reentrant: it marks the front future done
# before it shifts it off the list, so a callback that turns the loop while
# the handle is readable again reaches the same, already done, future.
use strict;
use warnings;
use IO::Poll qw( POLLIN );
use Future::IO;
use Future::IO::Impl::IOAsync;    # loaded implementation wins

pipe( my ( $r, $w ) ) or die $!;
syswrite $w, 'x';

my $first = Future::IO->poll( $r, POLLIN );
$first->on_done( sub {
   # new data on the same handle, then a blocking wait on it
   syswrite $w, 'y';
   Future::IO->poll( $r, POLLIN )->get;
} );

my $ok = eval { $first->get; 1 };
print $ok ? "OK: reentrant poll worked\n" : "DIED: $@";
exit( $ok ? 0 : 1 );
