#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(base_csaf_security_advisory exec_validator_optional_test);
use CSAF::Validator::OptionalTests;

# 6.2.2 Missing Remediation

# For each Product ID (type /$defs/product_id_t) in the Product Status groups Affected and Under investigation it MUST be tested that a
# remediation exists.

#   The remediation might be of the category none_available or no_fix_planned .


# The relevant paths for this test are:
#   /vulnerabilities[]/product_status/first_affected[]
#   /vulnerabilities[]/product_status/known_affected[]
#   /vulnerabilities[]/product_status/last_affected[]
#   /vulnerabilities[]/product_status/under_investigation[]

# Fail test:

# "product_tree": {
#   "full_product_names": [
#       {
#           "product_id": "CSAFPID-9080700",
#           "name": "Product A"
#       }
#   ]
# },
# "vulnerabilities": [
#   {
#       "product_status": {
#           "last_affected": [
#               "CSAFPID-9080700"
#           ]
#       }
#   }
# ]

my $csaf = base_csaf_security_advisory();

$csaf->product_tree->full_product_names->add(name => 'Product A', product_id => 'CSAFPID-9080700');
$csaf->product_tree->full_product_names->add(name => 'Product B', product_id => 'CSAFPID-9080701');

my $vulns = $csaf->vulnerabilities;
my $vuln  = $vulns->add(cve => 'CVE-2023-00000');

$vuln->product_status->last_affected(['CSAFPID-9080700']);

exec_validator_optional_test($csaf, '6.2.2');

done_testing;
