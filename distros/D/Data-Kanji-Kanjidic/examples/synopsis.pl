#!/home/ben/software/install/bin/perl
use warnings;
use strict;
binmode STDOUT, ":encoding(utf8)";
use Data::Kanji::Kanjidic 'parse_kanjidic';
my $kanji = parse_kanjidic ('/path/to/kanjidic');
for my $k (keys %$kanji) {
    print "$k has radical number $kanji->{$k}{radical}.\n";
}

