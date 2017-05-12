#!/usr/bin/perl -w
use strict;
use Convert::AcrossLite;

my $ac = Convert::AcrossLite->new();
$ac->in_file('/home/doug/puzzles/Easy.puz');
$ac->out_file('/home/doug/puzzles/Easy.txt');
$ac->puz2text;
