#!/usr/bin/env perl

##  get_indexes_associated_with_fields.pl

##  Large database files may have hundreds of fields and it is not always easy to
##  figure out what numerical index is associated with a given field.

##  At the same time, the constructor of the DecisionTree module requires that the
##  field that holds the class label and fields that contain the feature values be
##  specified by their numerical zero-based indexes.

##  If you have a very large database and you are faced with the problem described
##  above, you can run this script to see the zero-based numerical index values
##  associated with the different columns of your CSV file.

##  CALL SYNTAX:    get_indexes_associated_with_fields.pl    my_database_file.csv

use strict;
use warnings;

die "Call syntax:   get_indexes_associated_with_fields.pl  filename.csv"
         unless @ARGV == 1;

my $training_datafile = shift;

open FILEIN, $training_datafile or die "Unable to open $training_datafile: $!";
die("Aborted. Only CSV files allowed") unless $training_datafile =~ /\.csv$/;
my $firstline = <FILEIN>;
$firstline =~ s/\r?\n?$//;
my $record = cleanup_csv($firstline);
my @all_fields = split /,/, $record;
my %duplicate_detector;
map {$duplicate_detector{$_}++} @all_fields;
map { die "\n\nYour training file is NOT usable --- it contains duplicate field names" 
                                if $duplicate_detector{$_} > 1 } keys %duplicate_detector;
my $num_of_fields = scalar @all_fields;
print "\nNumber of fields: $num_of_fields\n";
my $all_fields_with_indexes = {map {$_ => $all_fields[$_]} 0 .. $num_of_fields-1};
my $all_fields_with_indexes_inverted = {map {$all_fields[$_] => $_} 0 .. $num_of_fields-1};

print "\nAll field names along with their positional indexes:\n";
foreach my $kee (sort {$a <=> $b} keys %{$all_fields_with_indexes}) {
    print "$kee=>$all_fields_with_indexes->{$kee}  ";
}
print "\n\nInverted index for field names:\n";
foreach my $kee (sort {$a cmp $b} keys %{$all_fields_with_indexes_inverted}) {
    print "$kee=>$all_fields_with_indexes_inverted->{$kee}  ";
}

sub cleanup_csv {
    my $line = shift;
    $line =~ tr/\/:?()[]{}'/          /;
    my @double_quoted = substr($line, index($line,',')) =~ /\"[^\"]+\"/g;
    for (@double_quoted) {
        my $item = $_;
        $item = substr($item, 1, -1);
        $item =~ s/^s+|,|\s+$//g;
        $item = join '_',  split /\s+/, $item;
        substr($line, index($line, $_), length($_)) = $item;
    }
    my @white_spaced = $line =~ /,(\s*[^,]+)(?=,|$)/g;
    for (@white_spaced) {
        my $item = $_;
        $item =~ s/\s+/_/g;
        $item =~ s/^\s*_|_\s*$//g;
        substr($line, index($line, $_), length($_)) = $item;
    }
    $line =~ s/,\s*(?=,|$)/,NA/g;
    return $line;
}

