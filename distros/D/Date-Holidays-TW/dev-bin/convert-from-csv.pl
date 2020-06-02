#!/usr/bin/env perl
# By CSV, I mean the dataset downloadable from here: https://data.gov.tw/dataset/26557

use v5.18;
use strict;
use warnings;
use utf8;

use Text::CSV;

my %CAL;

my $csv = Text::CSV->new ({ binary => 1 });

open my $fh, '<:utf8', $ARGV[0] or die $!;

$_ = <$fh>; # throw away the header line with BOM.

while ( my $row = $csv->getline($fh) ) {
    # "date","name","isHoliday","holidayCategory","description"
    my ($date, $name, $is_holiday, $holiday_category, $description) = @$row;
    my ($year, $month, $day) = split /\//, $date;

    $is_holiday = ($is_holiday eq "是") ? 1 : 0;

    my $mmdd = sprintf '%02d%02d', $month, $day;
    $CAL{$year}{$mmdd} = $is_holiday ? ($name || $holiday_category) : '';
}
close($fh);

# Hand-written dumper.
binmode STDOUT, ":utf8";
say 'my %CAL = (';
for my $year (sort keys %CAL) {
    say "    $year => {";
    for my $mmdd (sort keys %{$CAL{$year}}) {
        say "        \"$mmdd\" => \"$CAL{$year}{$mmdd}\",";
    }
    say "    },";
}
say ');';
