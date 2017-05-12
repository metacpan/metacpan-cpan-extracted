#!/usr/local/bin/perl

# This requires LWP to be installed.
use lib '.','..';

use Boulder::Genbank;
use Boulder::Stream;
$gb = new Boulder::Genbank(-accessor=>'Entrez',-param=>[qw/M57939 M28274 L36028/]);
$stream = new Boulder::Stream;

while (my $s = $gb->get) {
  $stream->put($s);
}
