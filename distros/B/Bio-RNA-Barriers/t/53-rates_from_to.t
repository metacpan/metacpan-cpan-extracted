#!perl -T
use 5.012;
use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::NoWarnings;            # produces one additional test!
use Test::Exception;
use File::Spec::Functions qw(catfile);
use File::Slurp qw(read_file);

my $test_count = 3**2 + 1;
plan tests => $test_count + 1;            # +1 for Test::NoWarnings

use Bio::RNA::Barriers;

# Data files
my $rate_matrix_file_txt = catfile qw(t data 12.rates.txt);

my @file_12_txt_rates = qw(
   0.06188    0.01468   0.002897
    0.2387          0          0
    0.2387          0          0
);


##############################################################################
##                              Test functions                              ##
##############################################################################

sub test_rates_from_to {
    my ($rate_matrix_file, $file_type, $rates_ref) = @_;
    # Open input data file and check it worked
    -s $rate_matrix_file
        or BAIL_OUT "empty or non-existent data file '$rate_matrix_file'";

    my $rate_matrix = Bio::RNA::Barriers::RateMatrix->new(
            file_name => $rate_matrix_file,
            file_type => $file_type,
    );

    can_ok $rate_matrix, qw(rate_from_to);
    my $dim = $rate_matrix->dim;
    my @rates = @$rates_ref;                # deep copy
    foreach my $i (1..$dim) {
        foreach my $j (1..$dim) {
            cmp_ok $rate_matrix->rate_from_to($i, $j),
                   '==',
                   shift @rates,
                   "$rate_matrix_file: rate from $i to $j"
                   ;
        }
    }
}


##############################################################################
##                                Call tests                                ##
##############################################################################

test_rates_from_to $rate_matrix_file_txt, 'TXT', \@file_12_txt_rates;


exit 0;

