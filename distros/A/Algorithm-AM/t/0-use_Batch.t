# test that the Algorithm::AM::Batch is loaded properly
# Algorithm::AM::Batch uses Import::Into to also import
# AM, Result, Project, and BigInt, so these must be
# checked as well.

use strict;
use warnings;
use Test::More tests => 9;
BEGIN {
    use_ok('Algorithm::AM::Batch')
        or BAIL_OUT(q{Couldn't load Algorithm::AM::Batch});
}
ok(scalar keys %Algorithm::AM::,
    'Algorithm::AM also imported');

ok(scalar keys %Algorithm::AM::Result::,
    'Algorithm::AM::Result also imported');

ok(scalar keys %Algorithm::AM::BigInt::,
    'Algorithm::AM::BigInt also imported');
ok(exists $::{bigcmp}, 'bigcmp imported from BigInt');

ok(scalar keys %Algorithm::AM::DataSet::,
    'Algorithm::AM::DataSet also imported');
ok(exists $::{dataset_from_file},
    'dataset_from_file imported from DataSet');

ok(scalar keys %Algorithm::AM::DataSet::Item::,
    'Algorithm::AM::DataSet::Item also imported');
ok(exists $::{new_item},
    'new_item imported from Item');

__END__