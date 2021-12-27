#!perl -T
use 5.012;
use strict;
use warnings;

use Test::More;
use Test::NoWarnings;            # produces one additional test!
use Test::Exception;
use File::Spec::Functions qw(catfile);
use File::Slurp qw(read_file);

my $test_count = 6;
plan tests => $test_count + 1;            # +1 for Test::NoWarnings

use Bio::RNA::Barriers;

# These should live
my $rate_matrix_file_txt = catfile qw(t data 12.rates.txt);
my $rate_matrix_file_bin = catfile qw(t data 12.rates.bin);

# These should die


##############################################################################
##                              Test functions                              ##
##############################################################################

sub test_construction_dies {
    my ($rate_matrix_file, $file_type, $descript) = @_;
    # Open input data file and check it worked
    open my $rate_matrix_fh, '<', $rate_matrix_file
        or BAIL_OUT "failed to open test data file '$rate_matrix_file'";

    dies_ok {
        Bio::RNA::Barriers::RateMatrix->new(
            file_handle => $rate_matrix_fh,
            file_type => $file_type,
        )
    } "rate matrix contruction: $descript dies";
}

sub test_construction_lives {
    my ($rate_matrix_file, $file_type, $descript) = @_;
    # Open input data file and check it worked
    open my $rate_matrix_fh, '<', $rate_matrix_file
        or BAIL_OUT "failed to open test data file '$rate_matrix_file'";

    lives_ok {
        Bio::RNA::Barriers::RateMatrix->new(
            file_handle => $rate_matrix_fh,
            file_type => $file_type,
        )
    } "rate matrix contruction: $descript lives";
}

sub test_construction_from_file_lives {
    my ($rate_matrix_file, $file_type, $descript) = @_;
    # Open input data file and check it worked
    -s $rate_matrix_file
        or BAIL_OUT "empty or non-existent data file '$rate_matrix_file'";

    lives_ok {
        Bio::RNA::Barriers::RateMatrix->new(
            file_name => $rate_matrix_file,
            file_type => $file_type,
        )
    } "rate matrix contruction: $descript lives";
}

##############################################################################
##                                Call tests                                ##
##############################################################################

test_construction_lives $rate_matrix_file_txt, 'TXT', 'txt matrix';
test_construction_lives $rate_matrix_file_bin, 'BIN', 'bin matrix';
test_construction_from_file_lives $rate_matrix_file_txt,
                                  'TXT',
                                  'txt matrix from file';

test_construction_dies  $rate_matrix_file_bin,
                        'FOOBAR',
                        'illegal mode specification dies'
                        ;
test_construction_dies  $rate_matrix_file_bin,
                        'TXT',
                        'bin matrix (wrong file type specified) dies'
                        ;
test_construction_dies  $rate_matrix_file_txt,
                        'BIN',
                        'TXT matrix (wrong file type specified) dies'
                        ;

exit 0;

