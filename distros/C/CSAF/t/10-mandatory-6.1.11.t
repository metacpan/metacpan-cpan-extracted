#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(base_csaf_security_advisory exec_validator_mandatory_test);

# 6.1.11 CWE

# It MUST be tested that given CWE exists and is valid.

# The relevant path for this test is:

#   /vulnerabilities[]/cwe

# Fail test:

#  "cwe": {
#    "id": "CWE-79",
#    "name": "Improper Input Validation"
#  }

my $csaf = base_csaf_security_advisory();

$csaf->product_tree->full_product_names->add(name => 'Product A', product_id => 'CSAFPID-9080700');

my $vulns = $csaf->vulnerabilities;
my $vuln  = $vulns->add(cve => 'CVE-2023-00000');

$vuln->cwe(id => 'CWE-79', name => 'Improper Input Validation');

exec_validator_mandatory_test($csaf, '6.1.11');

done_testing;
