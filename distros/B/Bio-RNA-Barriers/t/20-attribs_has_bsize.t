#!perl -T
use 5.012;
use strict;
use warnings;

use Test::More;
use Test::NoWarnings;            # produces one additional test!
use Test::Exception;
use File::Spec::Functions qw(catfile);
use File::Slurp qw(read_file);

my $test_count = 22 + 22 + 2*5*22;    # handles defined, # of minima in input files
plan tests => $test_count + 1;            # +1 for Test::NoWarnings

use Bio::RNA::Barriers;

my $barfile_with_bsize    = catfile qw(t data with_bsize.bar);
my $barfile_without_bsize = catfile qw(t data without_bsize.bar);


# Run actual tests.
{   # has_bsize == true
    # Open input data file and check it worked
    open my $barfh_with_bsize,    '<', $barfile_with_bsize
        or BAIL_OUT "failed to open test data file '$barfile_with_bsize'";

    my $bar_with_bsize = Bio::RNA::Barriers::Results->new($barfh_with_bsize);
    foreach my $i (1..$bar_with_bsize->min_count) {
        ok $bar_with_bsize->get_min($i)->has_bsize, "min $i has bsize";
    }
}

{   # has_bsize == false
    # Open input data file and check it worked
    open my $barfh_without_bsize, '<', $barfile_without_bsize
        or BAIL_OUT "failed to open test data file '$barfile_without_bsize'";

    my $bar_without_bsize = Bio::RNA::Barriers::Results->new($barfh_without_bsize);
    foreach my $i (1..$bar_without_bsize->min_count) {
        ok !$bar_without_bsize->get_min($i)->has_bsize, "min $i has no bsize";
    }
}

{   # Dies when accessing non-present bsize information -- 5 x #mins tests

    # Read the file once and reuse the text.
    my $barfile_content;
    eval {
        $barfile_content = read_file $barfile_without_bsize;
    };
    BAIL_OUT "failed to read test data file '$barfile_without_bsize'"
        if $@;

    open my $barfh_without_bsize, '<', \$barfile_content;   # handle to string

    sub non_existent_attrib_err {
        my ($attribute, $basin) = @_;
        my $message = "accessing non-existent attribute '$attribute' of "
                      . "basin $basin raises error";

        return $message;
    }

    {
        seek $barfh_without_bsize, 0, 0; # position handle at beginning of str
        my $bar_without_bsize
            = Bio::RNA::Barriers::Results->new($barfh_without_bsize);
        foreach my $min ($bar_without_bsize->mins) {
            dies_ok {$min->merged_struct_count}
                    non_existent_attrib_err 'merged_struct_count', $min->index;
        }
    }

    {
        seek $barfh_without_bsize, 0, 0; # position handle at beginning of str
        my $bar_without_bsize
            = Bio::RNA::Barriers::Results->new($barfh_without_bsize);
        foreach my $min ($bar_without_bsize->mins) {
            dies_ok {$min->father_struct_count}
                    non_existent_attrib_err 'father_struct_count', $min->index;
        }
    }

    {
        seek $barfh_without_bsize, 0, 0; # position handle at beginning of str
        my $bar_without_bsize
            = Bio::RNA::Barriers::Results->new($barfh_without_bsize);
        foreach my $min ($bar_without_bsize->mins) {
            dies_ok {$min->merged_basin_energy}
                    non_existent_attrib_err 'merged_basin_energy', $min->index;
        }
    }

    {
        seek $barfh_without_bsize, 0, 0; # position handle at beginning of str
        my $bar_without_bsize
            = Bio::RNA::Barriers::Results->new($barfh_without_bsize);
        foreach my $min ($bar_without_bsize->mins) {
            dies_ok {$min->grad_struct_count}
                    non_existent_attrib_err 'grad_struct_count', $min->index;
        }
    }

    {
        seek $barfh_without_bsize, 0, 0; # position handle at beginning of str
        my $bar_without_bsize
            = Bio::RNA::Barriers::Results->new($barfh_without_bsize);
        foreach my $min ($bar_without_bsize->mins) {
            dies_ok {$min->grad_basin_energy}
                    non_existent_attrib_err 'grad_basin_energy', $min->index;
        }
    }
}

{   # Dies NOT when accessing present bsize information -- 5 x #mins tests

    # Read the file once and reuse the text.
    my $barfile_content;
    eval {
        $barfile_content = read_file $barfile_with_bsize;
    };
    BAIL_OUT "failed to read test data file '$barfile_with_bsize'"
        if $@;

    open my $barfh_with_bsize, '<', \$barfile_content;   # handle to string

    sub existent_attrib_no_err {
        my ($attribute, $basin) = @_;
        my $message = "accessing existent attribute '$attribute' of "
                      . "basin $basin raises NO error";

        return $message;
    }

    {
        seek $barfh_with_bsize, 0, 0; # position handle at beginning of str
        my $bar_with_bsize
            = Bio::RNA::Barriers::Results->new($barfh_with_bsize);
        foreach my $min ($bar_with_bsize->mins) {
            lives_ok {$min->merged_struct_count}
                    existent_attrib_no_err 'merged_struct_count', $min->index;
        }
    }

    {
        seek $barfh_with_bsize, 0, 0; # position handle at beginning of str
        my $bar_with_bsize
            = Bio::RNA::Barriers::Results->new($barfh_with_bsize);
        foreach my $min ($bar_with_bsize->mins) {
            lives_ok {$min->father_struct_count}
                    existent_attrib_no_err 'father_struct_count', $min->index;
        }
    }

    {
        seek $barfh_with_bsize, 0, 0; # position handle at beginning of str
        my $bar_with_bsize
            = Bio::RNA::Barriers::Results->new($barfh_with_bsize);
        foreach my $min ($bar_with_bsize->mins) {
            lives_ok {$min->merged_basin_energy}
                    existent_attrib_no_err 'merged_basin_energy', $min->index;
        }
    }

    {
        seek $barfh_with_bsize, 0, 0; # position handle at beginning of str
        my $bar_with_bsize
            = Bio::RNA::Barriers::Results->new($barfh_with_bsize);
        foreach my $min ($bar_with_bsize->mins) {
            lives_ok {$min->grad_struct_count}
                    existent_attrib_no_err 'grad_struct_count', $min->index;
        }
    }

    {
        seek $barfh_with_bsize, 0, 0; # position handle at beginning of str
        my $bar_with_bsize
            = Bio::RNA::Barriers::Results->new($barfh_with_bsize);
        foreach my $min ($bar_with_bsize->mins) {
            lives_ok {$min->grad_basin_energy}
                    existent_attrib_no_err 'grad_basin_energy', $min->index;
        }
    }
}
