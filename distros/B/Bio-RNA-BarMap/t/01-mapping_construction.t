#!perl -T
use 5.012;
use strict;
use warnings;

use Test::More;
use File::Spec::Functions;

my $test_count = 2;
plan tests => $test_count;

use Bio::RNA::BarMap;

my $barfile = catfile qw(t data N1M7_barmap_1.out);

open my $barfh, '<', $barfile
    or BAIL_OUT "failed to open test data file '$barfile'";


SKIP:
{
    # Construct mapping object.
    my $mod_name = 'Bio::RNA::BarMap::Mapping';
    can_ok $mod_name, 'new';            # constructor is available
    my $bar_mapping = Bio::RNA::BarMap::Mapping->new($barfh);
    isa_ok $bar_mapping, $mod_name;
}

