#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(base_csaf_security_advisory exec_validator_mandatory_test);

# 6.1.13 PURL

# It MUST be tested that given PURL is valid.

# The relevant paths for this test are:

#   /product_tree/branches[](/branches[])*/product/product_identification_helper/purl
#   /product_tree/full_product_names[]/product_identification_helper/purl
#   /product_tree/relationships[]/full_product_name/product_identification_helper/purl

# Fail test:

#   "product_tree": {
#     "full_product_names": [
#       {
#         "name": "Product A",
#         "product_id": "CSAFPID-9080700",
#         "product_identification_helper": {
#           "purl": "pkg:maven/@1.3.4"
#         }
#       }
#     ]
#   }

my $csaf = base_csaf_security_advisory();

my $product = $csaf->product_tree->full_product_names->add(
    name                          => 'Product A',
    product_id                    => 'CSAFPID-9080700',
    product_identification_helper => {purl => 'pkg:maven/@1.3.4'}
);

exec_validator_mandatory_test($csaf, '6.1.13');

done_testing;
