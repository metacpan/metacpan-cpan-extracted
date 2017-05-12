#!/usr/bin/perl

use lib '../lib';
use strict;
use warnings;
use URI::Escape;

=head1 Summary

This is pretty clearly an emulation of the Seaside tutorial.  Except the
overhead for seaside is a bit bigger than this...  I'd say. There is no smoke
or mirrors here, just the raw code. We even implement our own 'prompt'...

This is meant to be as minimal (yet almost useful) example as possible, serving
as a very simple tutorial of the basic functionality.

=cut

use Continuity;
use Continuity::RequestCallbacks;
my $server = new Continuity;
$server->loop;

# Main is invoked when we get a new session
sub main {
  # We are given a handle to get new requests
  my $request = shift;

  # This keeps track of the number we're currently on
  my $counter = 0;

  # After we're done with that we enter a loop. Forever.
  while(1) {
    print "Displaying current count and waiting for instructions.\n";
    my $increment_link = $request->callback_link(
      '++' => sub { $counter++ }
    );
    my $decrement_link = $request->callback_link(
      '--' => sub { $counter-- }
    );
    $request->print("Count: $counter<br>$increment_link $decrement_link");
    $request->next->execute_callbacks;
    if($counter == 42) {
      $request->print(q{
        <h1>The Answer to Life, The Universe, and Everything</h1>
      });
    }
  }
}

1;

