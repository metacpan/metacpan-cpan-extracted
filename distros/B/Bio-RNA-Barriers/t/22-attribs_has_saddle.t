#!perl -T
use 5.012;
use strict;
use warnings;

use Test::More;
use Test::NoWarnings;            # produces one additional test!
use Test::Exception;
use File::Spec::Functions qw(catfile);
use File::Slurp qw(read_file);

my $test_count = 2*22 + 2*22;    # handles defined, # of minima in input files
plan tests => $test_count + 1;            # +1 for Test::NoWarnings

use Bio::RNA::Barriers;

my $barfile_with_saddle    = catfile qw(t data with_saddle.bar);
# no_bsize data also has no saddle
my $barfile_without_saddle = catfile qw(t data without_bsize.bar);


# Run actual tests.
{   # has_saddle_struct == true
    # Open input data file and check it worked
    open my $barfh_with_saddle,    '<', $barfile_with_saddle
        or BAIL_OUT "failed to open test data file '$barfile_with_saddle'";

    my $bar_with_saddle = Bio::RNA::Barriers::Results->new($barfh_with_saddle);
    foreach my $i (1..$bar_with_saddle->min_count) {
        ok $bar_with_saddle->get_min($i)->has_saddle_struct,
           "min $i has saddle_struct";
    }
}

{   # has_saddle_struct == false
    # Open input data file and check it worked
    open my $barfh_without_saddle, '<', $barfile_without_saddle
        or BAIL_OUT "failed to open test data file '$barfile_without_saddle'";

    my $bar_without_saddle = Bio::RNA::Barriers::Results->new($barfh_without_saddle);
    foreach my $i (1..$bar_without_saddle->min_count) {
        ok !$bar_without_saddle->get_min($i)->has_saddle_struct, "min $i has no saddle_struct";
    }
}

{   # Dies when accessing non-present saddle_struct information -- 1 x #mins tests

    # Read the file once and reuse the text.
    my $barfile_content;
    eval {
        $barfile_content = read_file $barfile_without_saddle;
    };
    BAIL_OUT "failed to read test data file '$barfile_without_saddle'"
        if $@;

    open my $barfh_without_saddle, '<', \$barfile_content;   # handle to string

    sub non_existent_attrib_err {
        my ($attribute, $basin) = @_;
        my $message = "accessing non-existent attribute '$attribute' of "
                      . "basin $basin raises error";

        return $message;
    }

    {
        seek $barfh_without_saddle, 0, 0; # position handle at beginning of str
        my $bar_without_saddle
            = Bio::RNA::Barriers::Results->new($barfh_without_saddle);
        foreach my $min ($bar_without_saddle->mins) {
            dies_ok {$min->saddle_struct}
                    non_existent_attrib_err 'saddle_struct', $min->index;
        }
    }
}

{   # Dies NOT when accessing present saddle_struct information -- 1 x #mins tests

    # Read the file once and reuse the text.
    my $barfile_content;
    eval {
        $barfile_content = read_file $barfile_with_saddle;
    };
    BAIL_OUT "failed to read test data file '$barfile_with_saddle'"
        if $@;

    open my $barfh_with_saddle, '<', \$barfile_content;   # handle to string

    sub existent_attrib_no_err {
        my ($attribute, $basin) = @_;
        my $message = "accessing existent attribute '$attribute' of "
                      . "basin $basin raises NO error";

        return $message;
    }

    {
        seek $barfh_with_saddle, 0, 0; # position handle at beginning of str
        my $bar_with_saddle
            = Bio::RNA::Barriers::Results->new($barfh_with_saddle);
        foreach my $min ($bar_with_saddle->mins) {
            lives_ok {$min->saddle_struct}
                    existent_attrib_no_err 'saddle_struct', $min->index;
        }
    }
}
