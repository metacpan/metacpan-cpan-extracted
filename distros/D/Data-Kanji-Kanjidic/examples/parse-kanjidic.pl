#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Data::Kanji::Kanjidic 'parse_kanjidic';
my $kanjidic = parse_kanjidic ('/home/ben/data/edrdg/kanjidic');
print "@{$kanjidic->{猫}{english}}\n";
# This prints out "cat".

