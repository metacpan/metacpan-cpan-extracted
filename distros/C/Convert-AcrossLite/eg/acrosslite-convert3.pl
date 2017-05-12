#!/usr/bin/perl -w
use strict;
use Convert::AcrossLite;

my $ac = Convert::AcrossLite->new();
$ac->in_file('/home/doug/puzzles/Easy.puz');
$ac->parse_file;
print "TITLE: " . $ac->get_title . "\n";
print "AUTHOR: " . $ac->get_author . "\n";
print "COPYRIGHT: " . $ac->get_copyright . "\n";
print "ROWS: " . $ac->get_rows . "\n";
print "COLUMNS: " . $ac->get_columns . "\n";
print "SOLUTION:\n";
foreach my $sol ($ac->get_solution) {
    print "$sol\n";
}
print "DIAGRAM:\n";
foreach my $diag ($ac->get_diagram) {
    print "$diag\n";
}
print "ACROSS CLUES:\n" . $ac->get_across_clues;
print "DOWN CLUES:\n" . $ac->get_down_clues;
