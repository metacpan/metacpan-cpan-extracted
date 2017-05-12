binmode STDOUT, ":utf8";
use Data::Kanji::Kanjidic 'parse_kanjidic';
use utf8;
my $kanji = parse_kanjidic ($ARGV[0]);
my %all_onyomi;
for my $k (keys %$kanji) {
    my $onyomi = $kanji->{$k}->{onyomi};
    if ($onyomi) {
        for my $o (@$onyomi) {
            push @{$all_onyomi{$o}}, $k;
        }
    }
}
for my $o (sort keys %all_onyomi) {
    if (@{$all_onyomi{$o}} > 1) {
        print "Same onyomi 「$o」 for 「@{$all_onyomi{$o}}」!\n";
    }
}
