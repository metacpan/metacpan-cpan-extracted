#!perl -T
use 5.012;
use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::NoWarnings;            # produces one additional test!
use Test::Exception;
use File::Spec::Functions qw(catfile);
use File::Slurp qw(read_file);

my $test_count = 2 * 4;
plan tests => $test_count + 1;            # +1 for Test::NoWarnings

use Bio::RNA::Barriers;

# Data files
my $rate_matrix_file_txt = catfile qw(t data 12.rates.txt);
my $rate_matrix_file_bin = catfile qw(t data 12.rates.bin);


##############################################################################
##                              Test functions                              ##
##############################################################################

sub test_keep_states {
    my ($rate_matrix_file, $file_type, $descript) = @_;
    # Open input data file and check it worked
    -s $rate_matrix_file
        or BAIL_OUT "empty or non-existent data file '$rate_matrix_file'";

    my $rate_matrix = Bio::RNA::Barriers::RateMatrix->new(
            file_name => $rate_matrix_file,
            file_type => $file_type,
    );

    # Save initial state
    my $init_dim    = $rate_matrix->dim;
    my $init_matrix = "$rate_matrix";

    $rate_matrix->keep_states(1..$init_dim);
    is "$rate_matrix",    $init_matrix, 'keep all states (cmp matrix)';
    is $rate_matrix->dim, $init_dim,    'keep all states (cmp dim)';

    $rate_matrix->keep_states($init_dim);       # destructive!
    is $rate_matrix->dim, 1, 'keep only last state';

    $rate_matrix->keep_states();                # destructive!
    is $rate_matrix->dim, 0, 'keep no state';
}


##############################################################################
##                                Call tests                                ##
##############################################################################

test_keep_states $rate_matrix_file_txt, 'TXT', 'txt matrix';
test_keep_states $rate_matrix_file_bin, 'BIN', 'bin matrix';


exit 0;

