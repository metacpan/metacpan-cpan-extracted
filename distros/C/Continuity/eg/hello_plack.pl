#!/usr/bin/perl

use lib '../lib';
use strict;
use Continuity;
use Continuity::Adapt::Plack;

my $server = Continuity->new(
  adapter => Continuity::Adapt::Plack->new,
  debug_level => 3,
);
$server->loop;

sub main {
  my $request = shift;
  print STDERR "Got request: $request\n";
  $request->print("Hello!");
  print STDERR "Printed hello... calling ->next\n";
  $request->next;
  print STDERR "Back from ->next!\n";
  $request->print("World!");
}

