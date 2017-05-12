use Data::Kanji::Kanjidic 'parse_kanjidic';
my $kanji = parse_kanjidic ('/home/ben/data/edrdg/kanjidic');
for my $k (keys %$kanji) {
    print "$k has radical number $kanji->{$k}{radical}.\n";
}
