#!/usr/bin/env perl

use strict;
use warnings;
use Spreadsheet::ParseExcel;
use Encode qw(from_to decode encode);
use FindBin;
use lib "$FindBin::Bin/../lib";
use Getopt::Long;
use List::MoreUtils qw(any);
use Module::Load; #load

use utf8;

my $file;
my $verbose;
my $country = 'DK';

my %countries = (
    DK => 1,
    GL => 2,
    FO => 3,
);

GetOptions ('file=s'   => \$file,      # string
            'verbose'  => \$verbose,   # flag
            'country=s'  => \$country)
or die("Error in command line arguments\n");

#translating to internal representation
my $country_internal = $countries{$country};

my $parser = Spreadsheet::ParseExcel->new();

my $workbook = $parser->parse($file);

if ( not defined $workbook ) {
    die $parser->error(), ".\n";
}

my $module = 'Business::'.$country.'::Postalcode';
load $module, 'get_all_data';

my $postalcodes = get_all_data();
my %postalcode_remainders;

$postalcode_remainders{$_}++ for (@{$postalcodes});

for my $worksheet ( $workbook->worksheets() ) {

    my ( $row_min, $row_max ) = $worksheet->row_range();
    my ( $col_min, $col_max ) = $worksheet->col_range();

    ROW: for my $row ( $row_min .. $row_max ) {
        my $record;

        my $string = '';
        my $separator = '';
        for my $col ( $col_min .. $col_max ) {

            my $cell = $worksheet->get_cell( $row, $col );

            if ($col == $col_max) {
                $separator = "\n";
            } else {
                $separator = ";";
            }

            if (not $cell) {
                $string .= $separator;
                next;
            }


            if ($col == 5) {

                my $col_country = $cell->value();

                if ($col_country ne $country_internal) {
                    if ($verbose) {
                        print STDERR "Skipping row ($row), another country\n";
                    }
                    next ROW;
                }
            }

            $string .= ($cell->value || '' ). $separator;
        }
        if (any { decode('UTF-8', $string) eq decode('UTF-8', $_) } @{$postalcodes} ) {
            if (exists $postalcode_remainders{$string}) {
                delete $postalcode_remainders{$string};
            }
            if ($verbose) {
                print "Known record:\n\t", encode('UTF-8', $string);
            }
        } else {
            print "New record:\n\t", encode('UTF-8', $string);
        }
    }
}

foreach my $remainder (keys %postalcode_remainders) {
    print "Obsolete record:\n\t", encode('UTF-8', $remainder);
}

exit 0;
