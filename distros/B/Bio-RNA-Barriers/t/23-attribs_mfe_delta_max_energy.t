#!perl -T
use 5.012;
use strict;
use warnings;

use Test::More;
use Test::NoWarnings;            # produces one additional test!
use File::Spec::Functions;


use Bio::RNA::Barriers;

my @test_data = (
    {
        file    => catfile(qw(t data 12.bar)),
        deltaE  => 10.0,
        mfe     => 0,
        maxE    => 10,
    },
    {
        file    => catfile(qw(t data disconnected.bar)),
        deltaE  => 8,
        mfe     => -5.1,
        maxE    => 2.9,
    },
);

plan tests => 3 * @test_data + 1;

sub read_bar_file {
    my ($barfile) = @_;

    open my $barfh, '<', $barfile
        or BAIL_OUT "failed to open test data file '$barfile'";

    my $bar_results = Bio::RNA::Barriers::Results->new($barfh, $barfile);

    return $bar_results;
}

# Test whether delta_E of given file matches the passed energy.
sub test_delta_energy {
    my ($bar_results, $delta_energy) = @_;

    cmp_ok $bar_results->delta_energy, '==', $delta_energy,
           $bar_results->file_name() . ': delta energy';
}

# Test whether mfe of given file matches the passed energy.
sub test_mfe {
    my ($bar_results, $mfe) = @_;

    cmp_ok $bar_results->mfe, '==', $mfe,
           $bar_results->file_name() . ': mfe';
}

# Test whether max energy of given file matches the passed energy.
sub test_max_energy {
    my ($bar_results, $max_energy) = @_;

    cmp_ok $bar_results->max_energy, '==', $max_energy,
           $bar_results->file_name() . ': max energy';
}


# Run tests.
for my $dat (@test_data) {
    my $bar_results = read_bar_file $dat->{file};
    test_mfe          $bar_results, $dat->{mfe};
    test_delta_energy $bar_results, $dat->{deltaE};
    test_max_energy   $bar_results, $dat->{maxE};
}


# EOF
