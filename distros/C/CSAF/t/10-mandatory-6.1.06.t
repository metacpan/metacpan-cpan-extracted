#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(base_csaf_security_advisory exec_validator_mandatory_test);
use CSAF::Validator::MandatoryTests;

# 6.1.6 Contradicting Product Status

# For each item in /vulnerabilities it MUST be tested that the same Product ID is not member of contradicting product status groups. The sets formed by the contradicting groups within one vulnerability item MUST be pairwise disjoint.

# Contradiction groups are:

#   Affected:
#     /vulnerabilities[]/product_status/first_affected[]
#     /vulnerabilities[]/product_status/known_affected[]
#     /vulnerabilities[]/product_status/last_affected[]

#   Not affected:
#     /vulnerabilities[]/product_status/known_not_affected[]

#   Fixed:
#     /vulnerabilities[]/product_status/first_fixed[]
#     /vulnerabilities[]/product_status/fixed[]

#   Under investigation:
#     /vulnerabilities[]/product_status/under_investigation[]

#   Note: An issuer might recommend (/vulnerabilities[]/product_status/recommended) a product version from any group - also from the affected group, i.e. if it was discovered that fixed versions introduce a more severe vulnerability.

# Fail test:

#  "product_tree": {
#    "full_product_names": [
#      {
#        "product_id": "CSAFPID-9080700",
#        "name": "Product A"
#      }
#    ]
#  },
#  "vulnerabilities": [
#    {
#      "product_status": {
#        "known_affected": [
#          "CSAFPID-9080700"
#        ],
#        "known_not_affected": [
#          "CSAFPID-9080700"
#        ]
#      }
#    }
#  ]

my $csaf = base_csaf_security_advisory();

$csaf->product_tree->full_product_names->add(name => 'Product A', product_id => 'CSAFPID-9080700');

my $vulns = $csaf->vulnerabilities;
my $vuln  = $vulns->add(cve => 'CVE-2023-00000');

$vuln->product_status->first_affected(['CSAFPID-9080700']);
$vuln->product_status->under_investigation(['CSAFPID-9080700']);

exec_validator_mandatory_test($csaf, '6.1.6');

done_testing;
