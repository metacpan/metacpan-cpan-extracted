#!/usr/bin/perl -w
use strict;
use Convert::AcrossLite;

my $ac = Convert::AcrossLite->new();
$ac->in_file('/home/doug/puzzles/Easy.puz');

#my ($across_ref, $down_ref) = $ac->get_across_down;
my $across_ref = $ac->get_across;

print "Across\n";
print "------\n";

my %across= %$across_ref;
foreach my $key (sort { $a <=> $b } keys %across) {
    print "Direction: $across{$key}{direction}\n";
    print "Clue Number: $across{$key}{clue_number}\n";
    print "Row: $across{$key}{row}\n";
    print "Col: $across{$key}{column}\n";
    print "Clue: $across{$key}{clue}\n";
    print "Solution: $across{$key}{solution}\n";
    print "Length: $across{$key}{length}\n\n";
}



print "Down\n";
print "----\n";

my $down_ref = $ac->get_down;

my %down= %$down_ref;
foreach my $key (sort { $a <=> $b } keys %down) {
    print "Direction: $down{$key}{direction}\n";
    print "Clue Number: $down{$key}{clue_number}\n";
    print "Row: $down{$key}{row}\n";
    print "Col: $down{$key}{column}\n";
    print "Clue: $down{$key}{clue}\n";
    print "Solution: $down{$key}{solution}\n";
    print "Length: $down{$key}{length}\n\n";
}
