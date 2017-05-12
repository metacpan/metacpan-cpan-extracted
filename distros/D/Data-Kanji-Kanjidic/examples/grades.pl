#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Data::Kanji::Kanjidic qw/parse_kanjidic grade/;
my $kanjidic = parse_kanjidic ('/home/ben/data/edrdg/kanjidic');
binmode STDOUT, ":utf8";
for my $grade (1..6) {
    my $list = grade ($kanjidic, $grade);
    print "Grade $grade:\n\n";
    my $count = 0;
    for (sort @$list) {
        print "$_ ";
        $count++;
        if ($count % 20 == 0) {
            print "\n";
        }
    }
    print "\n";
}

