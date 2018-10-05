use warnings;
use strict;
use Test::More;
use FindBin '$Bin';
use Data::Kanji::Kanjidic qw/parse_kanjidic kanjidic_order/;

my $k = parse_kanjidic ("$Bin/kanjidic-sample");
my @order = kanjidic_order ($k);
ok (@order == keys %$k);
my $prev = -1;
for my $o (@order) {
    my $s = $k->{$o}->{S}->[0];
    ok ($s >= $prev, "correctly ordered");
}

done_testing ();
