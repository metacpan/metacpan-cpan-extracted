#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(base_csaf_security_advisory exec_validator_mandatory_test);
use CSAF::Validator::MandatoryTests;

# 6.1.31 Version Range in Product Version

# For each element of type /$defs/branches_t with category of product_version it MUST be tested that the value of name does not contain a version range.

#    To implement this test it is deemed sufficient that, when converted to lower case, the value of name does not contain any of the following strings:

#      <
#      <=
#      >
#      >=
#      after
#      all
#      before
#      earlier
#      later
#      prior
#      versions

# The relevant paths for this test are:

#   /product_tree/branches[](/branches[])*/name


# Fail test:

#  "branches": [
#    {
#      "category": "product_version",
#      "name": "prior to 4.2",
#      // ...
#    }
#  ]

my $csaf = base_csaf_security_advisory();

my $branches = $csaf->product_tree->branches;
$branches->add(category => 'product_version', name => 'prior to 4.2');

exec_validator_mandatory_test($csaf, '6.1.31');

done_testing;
