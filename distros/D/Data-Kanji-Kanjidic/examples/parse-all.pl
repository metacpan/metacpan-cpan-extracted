use warnings;
use strict;
use Data::Kanji::Kanjidic 'parse_kanjidic';
use utf8;
binmode STDOUT, ":encoding(utf8)";
my %codes = %Data::Kanji::Kanjidic::codes;
my $kfile = '/home/ben/data/edrdg/kanjidic';
my $k = parse_kanjidic ($kfile);
my $n_kanjis = scalar keys %$k;
print "There are $n_kanjis kanjis in kanjidic.\n";
my $entry = $k->{米};
for my $y (sort {lc $a cmp lc $b} keys %$entry) {
    if ($codes{$y}) {
        print "$codes{$y} -> ";
    }
    print "\"$y\":";
    if (ref ($entry->{$y}) eq 'ARRAY') {
        print "[";
        my @q;
        for my $e (@{$entry->{$y}}) {
            push @q, "\"$e\"";
        }
        print join ",", @q;
        print "]";
    }
    elsif (ref ($entry->{$y}) eq 'HASH') {
        print "{";
        my @q;
        for my $e (keys %{$entry->{$y}}) {
            push @q, "\"$e\":\"$entry->{$y}{$e}\"";
        }
        print join ",", @q;
        print "}";
    }
    else {
        print "\"$entry->{$y}\"";
    }
    print ",";
    print "\n";
}
