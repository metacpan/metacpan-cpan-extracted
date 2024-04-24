#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(base_csaf_security_advisory exec_validator_mandatory_test);

# 6.1.23 Multiple Use of Same CVE

# It MUST be tested that a CVE is not used in multiple vulnerability items.

# The relevant path for this test is:

#   /vulnerabilities[]/cve

# Fail test:

#   "vulnerabilities": [
#     {
#       "cve": "CVE-2017-0145"
#     },
#     {
#       "cve": "CVE-2017-0145"
#     }
#   ]

my $csaf = base_csaf_security_advisory();

$csaf->product_tree->full_product_names->add(name => 'Product A', product_id => 'CSAFPID-9080700');

my $vulns = $csaf->vulnerabilities;
$vulns->add(cve => 'CVE-2017-0145');
$vulns->add(cve => 'CVE-2017-0145');

exec_validator_mandatory_test($csaf, '6.1.23');

done_testing;
