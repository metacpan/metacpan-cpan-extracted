#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Data::Kanji::Kanjidic 'parse_kanjidic';
my $kanji = parse_kanjidic ('/home/ben/data/edrdg/kanjidic');
my @sorted;
for my $k (keys %$kanji) {
    if ($kanji->{$k}->{F}) {
        push @sorted, $kanji->{$k};
    }
}
@sorted = sort {$a->{F} <=> $b->{F}} @sorted;
binmode STDOUT, ":utf8";
for (@sorted) {
    print "$_->{kanji}: $_->{F}\n";
}

