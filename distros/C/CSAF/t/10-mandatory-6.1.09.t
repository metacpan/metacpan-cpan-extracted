#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(base_csaf_security_advisory exec_validator_mandatory_test);
use CSAF::Validator::MandatoryTests;

# 6.1.9 Invalid CVSS computation

# It MUST be tested that the given CVSS object has the values computed correctly according to the definition.

#    The vectorString SHOULD take precedence.

# The relevant paths for this test are:

#   /vulnerabilities[]/scores[]/cvss_v2/baseScore
#   /vulnerabilities[]/scores[]/cvss_v2/temporalScore
#   /vulnerabilities[]/scores[]/cvss_v2/environmentalScore
#   /vulnerabilities[]/scores[]/cvss_v3/baseScore
#   /vulnerabilities[]/scores[]/cvss_v3/baseSeverity
#   /vulnerabilities[]/scores[]/cvss_v3/temporalScore
#   /vulnerabilities[]/scores[]/cvss_v3/temporalSeverity
#   /vulnerabilities[]/scores[]/cvss_v3/environmentalScore
#   /vulnerabilities[]/scores[]/cvss_v3/environmentalSeverity

# Fail test:

#  "cvss_v3": {
#    "version": "3.1",
#    "vectorString": "CVSS:3.1/AV:L/AC:L/PR:H/UI:R/S:U/C:H/I:H/A:H",
#    "baseScore": 10.0,
#    "baseSeverity": "LOW"
#  }

my $csaf = base_csaf_security_advisory();

$csaf->product_tree->full_product_names->add(name => 'Product A', product_id => 'CSAFPID-9080700');

my $vulns = $csaf->vulnerabilities;
my $vuln  = $vulns->add(cve => 'CVE-2023-00000');

$vuln->scores->add(
    products => ['CSAFPID-9080700'],
    cvss_v3  =>
        {baseScore => 10.0, baseSeverity => 'LOW', vectorString => 'CVSS:3.1/AV:L/AC:L/PR:H/UI:R/S:U/C:H/I:H/A:H'}
);

$vuln->scores->add(
    products => ['CSAFPID-9080700'],
    cvss_v2  => {baseScore => 10.0, vectorString => 'AV:N/AC:L/Au:N/C:C/I:C/A:C'}
);

exec_validator_mandatory_test($csaf, '6.1.9');
done_testing;
