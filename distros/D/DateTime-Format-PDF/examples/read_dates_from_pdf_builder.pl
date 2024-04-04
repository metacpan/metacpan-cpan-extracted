#!/usr/bin/env perl

use strict;
use warnings;

use DateTime::Format::PDF;
use PDF::Builder;

if (@ARGV < 1) {
        print STDERR "Usage: $0 pdf_file\n";
        exit 1;
}
my $pdf_file = $ARGV[0];

# Open file.
my $pdf = PDF::Builder->open($pdf_file);

# Parser.
my $pdf_date_parser = DateTime::Format::PDF->new;

my ($dt_created, $dt_modified);
my $print_format = "%a, %d %b %Y %H:%M:%S %z";
if (defined $pdf->created) {
        $dt_created = $pdf_date_parser->parse_datetime($pdf->created);
        print "Created: ".$dt_created->strftime($print_format)."\n";
}
if (defined $pdf->modified) {
        $dt_modified = $pdf_date_parser->parse_datetime($pdf->modified);
        print "Modified: ".$dt_modified->strftime($print_format)."\n";
}

# Output:
# Created: Fri, 15 May 2009 08:40:48 +0200
# Modified: Fri, 15 May 2009 08:44:00 +0200