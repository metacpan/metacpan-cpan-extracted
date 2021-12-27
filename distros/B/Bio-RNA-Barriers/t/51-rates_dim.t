#!perl -T
use 5.012;
use strict;
use warnings;

use Test::More;
use Test::NoWarnings;            # produces one additional test!
use Test::Exception;
use File::Spec::Functions qw(catfile);
use File::Slurp qw(read_file);

my $test_count = 2;
plan tests => $test_count + 1;            # +1 for Test::NoWarnings

use Bio::RNA::Barriers;

# Data files
my $rate_matrix_file_txt = catfile qw(t data 12.rates.txt);
my $rate_matrix_file_bin = catfile qw(t data 12.rates.bin);


##############################################################################
##                              Test functions                              ##
##############################################################################

sub test_dim {
    my ($rate_matrix_file, $file_type, $dim, $descript) = @_;
    # Open input data file and check it worked
    -s $rate_matrix_file
        or BAIL_OUT "empty or non-existent data file '$rate_matrix_file'";

    my $rate_matrix = Bio::RNA::Barriers::RateMatrix->new(
            file_name => $rate_matrix_file,
            file_type => $file_type,
    );
    is $rate_matrix->dim, $dim, "dimension of $descript";
}


##############################################################################
##                                Call tests                                ##
##############################################################################

test_dim $rate_matrix_file_txt, 'TXT', 3, 'txt matrix';
test_dim $rate_matrix_file_bin, 'BIN', 3, 'bin matrix';


exit 0;

