#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(exec_validator_mandatory_test);
use CSAF;

# 6.1.27.7 VEX Product Status

# For each item in /vulnerabilities it MUST be tested that at least one of the elements fixed, known_affected, known_not_affected, or under_investigation is present in product_status.

# The relevant value for /document/category is:

#   csaf_vex

# The relevant paths for this test are:

#   /vulnerabilities[]/product_status/fixed
#   /vulnerabilities[]/product_status/known_affected
#   /vulnerabilities[]/product_status/known_not_affected
#   /vulnerabilities[]/product_status/under_investigation

# Fail test:

#  "product_status": {
#    "first_fixed": [
#      // ...
#    ],
#    "recommended": [
#      // ...
#    ]
#  }

my $csaf = CSAF->new;

$csaf->document->title('Mandatory test: 6.1.27.7');
$csaf->document->category('csaf_vex');
$csaf->document->publisher(category => 'vendor', name => 'CSAF', namespace => 'https://csaf.io');

my $tracking = $csaf->document->tracking(
    id                   => 'CSAF:2023-001',
    status               => 'final',
    version              => '1.0.0',
    initial_release_date => 'now',
    current_release_date => 'now'
);

$csaf->product_tree->full_product_names->add(name => 'Product A', product_id => 'CSAFPID-9080700');

my $vulns = $csaf->vulnerabilities;
my $vuln  = $vulns->add(cve => 'CVE-2023-00000');

$vuln->product_status->first_fixed(['CSAFPID-9080700']);
$vuln->product_status->recommended(['CSAFPID-9080700']);

exec_validator_mandatory_test($csaf, '6.1.27.7');

done_testing;
