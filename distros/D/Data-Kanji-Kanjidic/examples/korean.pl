use Data::Kanji::Kanjidic 'parse_kanjidic';
use Lingua::KO::Munja ':all';
binmode STDOUT, ":utf8";
my $kanji = parse_kanjidic ($ARGV[0]);
for my $k (sort keys %$kanji) {
    my $w = $kanji->{$k}->{W};
    if ($w) {
        my @h = map {'"' . hangul2roman ($_) . '"'} @$w;
        print "$k is Korean ", join (", ", @h), "\n";
    }
}
