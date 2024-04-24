#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(base_csaf_security_advisory exec_validator_mandatory_test);
use CSAF::Validator::MandatoryTests;

# 6.1.7 Multiple Scores with same Version per Product

# For each item in /vulnerabilities it MUST be tested that the same Product ID is not member of more than one CVSS-Vectors with the same version.

# The relevant path for this test is:

#   /vulnerabilities[]/scores[]

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
#      "scores": [
#        {
#          "products": [
#            "CSAFPID-9080700"
#          ],
#          "cvss_v3": {
#            "version": "3.1",
#            "vectorString": "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H",
#            "baseScore": 10,
#            "baseSeverity": "CRITICAL"
#          }
#        },
#        {
#          "products": [
#            "CSAFPID-9080700"
#          ],
#          "cvss_v3": {
#            "version": "3.1",
#            "vectorString": "CVSS:3.1/AV:L/AC:L/PR:H/UI:R/S:U/C:H/I:H/A:H",
#            "baseScore": 6.5,
#            "baseSeverity": "MEDIUM"
#          }
#        }
#      ]
#    }
#  ]

my $csaf = base_csaf_security_advisory();

$csaf->product_tree->full_product_names->add(name => 'Product A', product_id => 'CSAFPID-9080700');

my $vulns = $csaf->vulnerabilities;
my $vuln  = $vulns->add(cve => 'CVE-2023-00000');

$vuln->scores->add(
    products => ['CSAFPID-9080700'],
    cvss_v3  =>
        {baseSeverity => 'CRITICAL', baseScore => 10, vectorString => 'CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H'}
);

$vuln->scores->add(
    products => ['CSAFPID-9080700'],
    cvss_v3  =>
        {baseSeverity => 'CRITICAL', baseScore => 10, vectorString => 'CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H'}
);

exec_validator_mandatory_test($csaf, '6.1.7');

done_testing;
