#!perl -T
use 5.012;
use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Spec::Functions;

use Bio::RNA::BarMap;


my $test_count = 5;
plan tests => $test_count;

my $barfile = catfile qw(t data N1M7_barmap_1.out);

open my $barfh, '<', $barfile
    or BAIL_OUT "failed to open test data file '$barfile'";

SKIP:
{
    # Construct mapping object.
    my $bar_mapping = Bio::RNA::BarMap::Mapping->new($barfh);
    my $expected_barriers_file_count = 32;

    # Check for mapping methods
    subtest 'Mapping has file mapping methods' => sub {
        can_ok $bar_mapping, 'mapped_files';
        can_ok $bar_mapping, 'first_mapped_file';
        can_ok $bar_mapping, 'map_file';
        can_ok $bar_mapping, 'map_file_inv';
    };

    # Check we found all bar files in the mapping file, and their names are
    # non-zero.
    subtest 'mapped_files(): count and positive length' => sub {
        plan tests => 2;

        my @barriers_files      = $bar_mapping->mapped_files;
        my $barriers_file_count = @barriers_files;
        cmp_ok $barriers_file_count,
               '==',
               $expected_barriers_file_count,
               "Barriers file count",
               ;

        cmp_ok scalar( grep {length $_ > 0} @barriers_files ),
               '==',
               $expected_barriers_file_count,
               "Barriers file names are defined and non-empty",
               ;
    };

    subtest 'first_mapped_file() ' => sub {
        plan tests => 2;

        my $first_file_mapped_files = ($bar_mapping->mapped_files)[0];
        is $bar_mapping->first_mapped_file,
           $first_file_mapped_files,
           'first_mapped_file() returns mapped_files[0]';

        is '8.bar',
           $first_file_mapped_files,
           'first_mapped_file() returns 8.bar';
    };

    subtest 'map_file' => sub {
        plan tests => 5;

        is $bar_mapping->map_file('8.bar'),
           '9.bar',
           'map_file(): file 8.bar maps to 9.bar'
           ;
        is $bar_mapping->map_file('20.bar'),
           '21.bar',
           'map_file(): file 20.bar maps to 21.bar'
           ;
        is $bar_mapping->map_file('38.bar'),
           '39.bar',
           'map_file(): file 38.bar maps to 39.bar'
           ;
        isnt defined $bar_mapping->map_file('39.bar'),
           'map_file(): file 39.bar has no successor'
           ;
        throws_ok {$bar_mapping->map_file('FOO.bar')}
                  qr{not contained in BarMap file},
                  'file not contained thrown'
                  ;
    };

    subtest 'map_file_inv' => sub {
        plan tests => 5;

        is $bar_mapping->map_file_inv('9.bar'),
           '8.bar',
           'map_file(): file 9.bar is inversely mapped to 8.bar'
           ;
        is $bar_mapping->map_file_inv('21.bar'),
           '20.bar',
           'map_file(): file 21.bar is inversely mapped to 20.bar'
           ;
        is $bar_mapping->map_file_inv('39.bar'),
           '38.bar',
           'map_file(): file 39.bar is inversely mapped to 38.bar'
           ;
        isnt defined $bar_mapping->map_file_inv('8.bar'),
           'map_file(): file 8.bar has no successor'
           ;
        throws_ok {$bar_mapping->map_file_inv('FOO.bar')}
                  qr{not contained in BarMap file},
                  'file not contained thrown'
                  ;
    };
}

