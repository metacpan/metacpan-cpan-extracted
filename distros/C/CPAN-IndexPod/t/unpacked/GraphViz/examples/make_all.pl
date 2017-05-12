#!/usr/bin/perl -w

use strict;
use Config;
use IPC::Run qw(run);
$| = 1;

my $perl = $Config{'perlpath'};

print "Attempting to make all images...\n";

my($in, $out, $err);

foreach my $file (sort <*.pl>) {
  next if $file =~ /make_all\.pl/;
  next if $file =~ /primes_aux\.pl/;
  next if $file =~ /redcarpet\.pl/;
  next if $file =~ /ppmgraph\.pl/;
  print "  Running $file...";
  run [$perl, "./$file"], \$in, \$out, \$err; # throw the output away
  print "done\n";
}

print "All images made.\n";
