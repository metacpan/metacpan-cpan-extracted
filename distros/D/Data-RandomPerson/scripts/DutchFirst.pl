#!/usr/bin/perl
use strict;
use warnings;
use v5.14;

use Path::Tiny;

my $female_file = '../share/DutchFemale.tsv';
my $male_file = '../share/DutchMale.tsv';

path($female_file)->remove;
path($male_file)->remove;

my $input_file = 'Top_eerste_voornamen_NL_2010.csv';
open (my $fh, "< :encoding(Latin1)", $input_file)
    or die "Could not open file";

my $linecounter;
while (my $row = <$fh>) {
    # I know, I know
    chomp $row;
    my @fields = split(';', $row);
    $linecounter++;
    next if $linecounter <= 2;
    if ($fields[1]) {
        path($female_file)->append_utf8(
            join("\t", $fields[1], $fields[2] =~ s/\.//r) . "\n");
    }
    if ($fields[3]) {
        path($male_file)->append_utf8(
            join("\t", $fields[3], $fields[4] =~ s/\.//r) . "\n");
    }
}
