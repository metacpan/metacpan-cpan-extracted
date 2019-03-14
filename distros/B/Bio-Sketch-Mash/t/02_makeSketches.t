#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use FindBin qw/$RealBin/;
use JSON ();
use lib "$RealBin/../lib";

use Test::More tests=>1;
use Bio::Sketch::Mash;

my $msh = Bio::Sketch::Mash->new("$RealBin/data/PNUSAL003567_R1_.fastq.gz.msh"); 
$msh->writeJson("$RealBin/data/PNUSAL003567_R1_.fastq.gz.msh.json");

my $mashInfo = `mash info -d $RealBin/data/PNUSAL003567_R1_.fastq.gz.msh`;
my $jsonInfo = `cat $RealBin/data/PNUSAL003567_R1_.fastq.gz.msh.json`;

my $json=JSON->new;
$json->utf8;           # If we only expect characters 0..255. Makes it fast.
$json->allow_nonref;   # can convert a non-reference into its corresponding string
$json->allow_blessed;  # encode method will not barf when it encounters a blessed reference
$json->pretty;         # enables indent, space_before and space_after

is_deeply($json->decode($mashInfo), $json->decode($jsonInfo), "Read/write R1");
