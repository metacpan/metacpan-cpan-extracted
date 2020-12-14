#!/usr/bin/perl

use strict;
use warnings;

use Encode;
use Calendar::Japanese::Holiday;

sub utf8_off {
    my ($str) = @_;
    $str = Encode::encode('utf8', $str) if Encode::is_utf8($str);
    return $str;
}

foreach my $year (2020 .. 2022) {
    foreach my $m (1 .. 12) {
	my $h = getHolidays($year, $m, 1);
	foreach my $d (sort {int $a <=> int $b} keys %$h) {
	    print sprintf("%04d-%02d-%02d:%s\n", $year, $m, $d, utf8_off($h->{$d}));
	}
    }
}

