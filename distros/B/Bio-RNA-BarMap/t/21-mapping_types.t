#!perl -T
use 5.012;
use strict;
use warnings;

use Test::More;
use File::Spec::Functions;

use Bio::RNA::BarMap;

my $test_count = 4;
plan tests => $test_count;

my $barfile = catfile qw(t data N1M7_barmap_1.out);
open my $barfh, '<', $barfile
    or BAIL_OUT "failed to open test data file '$barfile'";


SKIP:
{
    # Construct mapping object.
    my $bar_mapping = Bio::RNA::BarMap::Mapping->new($barfh);

    subtest 'Mapping::Type provides mapping type methods' => sub {
        plan tests => 3;

        can_ok 'Bio::RNA::BarMap::Mapping::Type', 'is_exact';
        can_ok 'Bio::RNA::BarMap::Mapping::Type', 'is_approx';
        can_ok 'Bio::RNA::BarMap::Mapping::Type', 'arrow';
    };

    # Test whether the single-step mapping has the correct type (i.e. exact or
    # approx, as indicated by the arrows -> and ~>, respectively).
    subtest 'Mapping types (exact/approx), single step' => sub {
        my $from_file   = '26.bar';
        my %from_to_min = (             # true mapping from file
            12 => [ 3, '->'],
            77 => [48, '->'],
            89 => [26, '~>'],
            96 => [75, '~>'],
        );
        plan tests => 3 * keys %from_to_min;

        # Verify each entry.
        while (my ($from_min, $true_mapping) = each %from_to_min) {
            my ($true_to_min, $true_arrow) = @$true_mapping;
            my ($mapping_type, $to_min)
                = $bar_mapping->map_min_step($from_file, $from_min);

            # Is the min mapped correctly?
            cmp_ok $to_min, '==', $true_to_min,
                   "min $from_min from file $from_file maps to $true_to_min";

            # Arrow '->' means exact mapping, '~>' means approx mapping.
            my $has_correct_type = $true_arrow eq '->'
                ? $mapping_type->is_exact()
                : $mapping_type->is_approx()
                ;
            ok $has_correct_type,
               "Mapping type of min $from_min from $from_file";

            # Compare arrow strings.
            my $arrow = $mapping_type->arrow();
            is $arrow, $true_arrow, "Arrow of min $from_min from $from_file";
        }
    };

    subtest 'Mapping provides mapping type methods' => sub {
        plan tests => 2;

        can_ok $bar_mapping, 'get_mapping_type';
        can_ok $bar_mapping, 'get_mapping_arrow';
    };

    # Test whether the multi-step mapping has the correct type (i.e. exact or
    # approx, as indicated by the arrows -> and ~>, respectively). A
    # multi-step mapping is exact iff all of its single-step mappings are
    # exact.
    subtest 'Mapping types (exact/approx), multi-step' => sub {
        my $from_file   = '27.bar';
        my $to_file     = '35.bar';
        my %from_to_min = (             # true mapping from file
             1 => [ 2, '->'],
             3 => [10, '->'],
            56 => [11, '~>'],
            86 => [63, '~>'],
        );
        plan tests => 5 * keys %from_to_min;

        # Verify each entry.
        while (my ($from_min, $true_mapping) = each %from_to_min) {
            my ($true_to_min, $true_arrow) = @$true_mapping;
            my ($mapping_type, $to_min)
                = $bar_mapping->map_min($from_file, $from_min, $to_file);

            # Is the min mapped correctly?
            cmp_ok $to_min, '==', $true_to_min,
                   "min $from_min from file $from_file maps to $true_to_min in $to_file";

            # Arrow '->' means exact mapping, '~>' means approx mapping.
            my $has_correct_type = $true_arrow eq '->'
                ? $mapping_type->is_exact()
                : $mapping_type->is_approx()
                ;
            ok $has_correct_type,
               "Mapping type of min $from_min from file $from_file to $to_file";

            # Use convenience method for type.
            my $mapping_type_direct = $bar_mapping->get_mapping_type(
                $from_file, $from_min, $to_file);
            my $has_correct_type_direct = $true_arrow eq '->'
                ? $mapping_type_direct->is_exact()
                : $mapping_type_direct->is_approx()
                ;
            ok $has_correct_type_direct,
               "Mapping type of min $from_min (get_mapping_type())";

            # Compare arrow strings.
            my $arrow = $mapping_type->arrow();
            is $arrow, $true_arrow, "Arrow of min $from_min from $from_file to $to_file";

            # Use convenience method for arrow.
            $arrow = $bar_mapping->get_mapping_arrow(
                $from_file, $from_min, $to_file);
            is $arrow, $true_arrow, "Arrow of min $from_min (get_mapping_arrow())";
        }
    };
}

# End of t/21-mapping_types.t
