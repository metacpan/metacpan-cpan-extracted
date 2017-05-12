#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Data::Kanji::Kanjidic 'parse_kanjidic';
binmode STDOUT, ":utf8";
my $kanji = parse_kanjidic ("/home/ben/data/edrdg/kanjidic");
for my $k (sort keys %$kanji) {
    my $mo = $kanji->{$k}->{morohashi};
    if ($mo) {
        print "$k: volume $mo->{volume}, page $mo->{page}, index $mo->{index}.\n";
    }
}

