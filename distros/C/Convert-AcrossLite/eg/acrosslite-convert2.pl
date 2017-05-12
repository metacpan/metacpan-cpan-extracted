#!/usr/bin/perl -w
use strict;
use Convert::AcrossLite;

my $ac = Convert::AcrossLite->new();
$ac->in_file('/home/doug/puzzles/Easy.puz');

print $ac->puz2text;
