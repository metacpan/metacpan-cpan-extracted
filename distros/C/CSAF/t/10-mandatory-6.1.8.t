#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(base_csaf_security_advisory exec_validator_mandatory_test);
use CSAF::Validator::MandatoryTests;

# 6.1.8 Invalid CVSS

# It MUST be tested that the given CVSS object is valid according to the referenced schema.

# The relevant paths for this test are:

#   /vulnerabilities[]/scores[]/cvss_v2
#   /vulnerabilities[]/scores[]/cvss_v3

# Fail test:

#  "cvss_v3": {
#    "version": "3.1",
#    "vectorString": "CVSS:3.1/AV:L/AC:L/PR:H/UI:R/S:U/C:H/I:H/A:H",
#    "baseScore": 6.5
#  }

my $csaf = base_csaf_security_advisory();

$csaf->product_tree->full_product_names->add(name => 'Product A', product_id => 'CSAFPID-9080700');

my $vulns = $csaf->vulnerabilities;
my $vuln  = $vulns->add(cve => 'CVE-2023-00000');

# Check CVSS (2.0 and 3.x) JSON Schema

$vuln->scores->add(
    products => ['CSAFPID-9080700'],
    cvss_v2  => {baseScore => 6.5, vectorString => 'CVSS:3.1/AV:L/AC:L/PR:H/UI:R/S:U/C:H/I:H/A:H'}
);

exec_validator_mandatory_test($csaf, '6.1.8');

done_testing;
