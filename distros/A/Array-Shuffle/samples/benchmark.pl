#!/usr/bin/perl

use strict;
use warnings;

use List::Util qw(shuffle);
use Array::Shuffle qw(shuffle_array shuffle_huge_array);

use Benchmark qw(cmpthese);

sub shuffle_perl (\@) {
    my $a = shift;
    if (@$a > 1) {
        my $i = @$a;
        while (--$i) {
            my $j = int rand($i + 1);
            my $tmp = $a->[$i];
            $a->[$i] = $a->[$j];
            $a->[$j] = $tmp
        }
    }
}

$| = 1;
my @a;
my $f = 10 ** (1/3);
for (my $n = 1; ; $n *= $f) {
    print "Generating array with " . int($n) . " elements...\n";
    my $c;
    my $s = $#a; $#a = $n; $#a = $s;
    while (@a < $n) {
        push @a, int(rand 1000000), 1..1000;
        unless ($c--) {
            printf "%4.2f%%\r", 100 * @a / $n;
            $c = 100;
        }
    }
    system "ps vp $$";
    print "Shuffling it...\n";

    my %bm = (sa  => sub { shuffle_array @a },
              sha => sub { shuffle_huge_array @a });

    if ($n <= 1_000_000) {
        $bm{lu} = sub { @a = shuffle @a };
        $bm{pp} = sub { shuffle_perl @a };
    }

    cmpthese(-1, \%bm);
}
