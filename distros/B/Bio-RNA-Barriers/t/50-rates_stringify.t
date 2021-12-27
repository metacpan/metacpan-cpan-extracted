#!perl -T
use 5.012;
use strict;
use warnings;

use Test::More;
use Test::NoWarnings;            # produces one additional test!
use Test::Exception;
use File::Spec::Functions qw(catfile);
use File::Slurp qw(read_file);

my $test_count = 4;
plan tests => $test_count + 1;            # +1 for Test::NoWarnings

use Bio::RNA::Barriers;

my ($rate_matrix_data_txt, $rate_matrix_data_bin);
eval {
    $rate_matrix_data_txt = read_file catfile qw(t data 12.rates.txt);
    $rate_matrix_data_bin
        = read_file catfile(qw(t data 12.rates.bin)), binmode => ':raw';
};
BAIL_OUT "failed to open test data file: $@" if $@;

# Construct rate matrix from exact binary data.
open my $rate_matrix_fh_bin, '<', \$rate_matrix_data_bin;
my $rate_matrix = Bio::RNA::Barriers::RateMatrix->new(
    file_handle => $rate_matrix_fh_bin,
    file_type   => 'BIN',
);


##### Run tests #####
can_ok $rate_matrix, qw( stringify serialize );
is $rate_matrix->stringify, $rate_matrix_data_txt, 'stringifies correctly';
is "$rate_matrix",          $rate_matrix_data_txt, 'stringify overloading';
is $rate_matrix->serialize, $rate_matrix_data_bin, 'serializes correctly';


exit 0;

