#! /usr/bin/env perl

# this script creates the data file containing Dutch last names.
# it loads files from the list curated by Gerrit Bloothoooft
# and made available under the 'Creative Commons 
# "Naamsvermelding-Gelijk delen 3.0 Nederland" license.
# I obtained it from http://www.naamkunde.net/?page_id=294

use strict;
use warnings;
use v5.14;

use Path::Tiny;
use XML::LibXML;

my $inputfile = 'fn_10kw.xml';
my $outputfile = '../share/DutchLast.tsv';

path($outputfile)->remove;
my $dom = XML::LibXML->load_xml(location => $inputfile);

foreach my $record ($dom->findnodes('//record')) {
    my $prefix =  $record->findvalue('./prefix');
    my $full_name = $prefix ? $prefix . ' ' : '';
    $full_name .= $record->findvalue('./naam');
    path($outputfile)->append_utf8(
        $full_name . "\t" . 
        $record->findvalue('./n2007') . "\n");
}

