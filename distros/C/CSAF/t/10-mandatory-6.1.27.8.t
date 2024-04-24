#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(exec_validator_mandatory_test);
use CSAF;

# 6.1.27.8 Vulnerability ID

# For each item in /vulnerabilities it MUST be tested that at least one of the elements cve or ids is present.

# The relevant value for /document/category is:

#   csaf_vex

# The relevant paths for this test are:

#   /vulnerabilities[]/cve
#   /vulnerabilities[]/ids


# Fail test:

#  "vulnerabilities": [
#    {
#      "title": "A vulnerability item without a CVE or ID"
#    }
#  ]

my $csaf = CSAF->new;

$csaf->document->title('Mandatory test: 6.1.27.8');
$csaf->document->category('csaf_vex');
$csaf->document->publisher(category => 'vendor', name => 'CSAF', namespace => 'https://csaf.io');

my $tracking = $csaf->document->tracking(
    id                   => 'CSAF:2023-001',
    status               => 'final',
    version              => '1.0.0',
    initial_release_date => 'now',
    current_release_date => 'now'
);

my $vulns = $csaf->vulnerabilities;
my $vuln  = $vulns->add(title => 'A vulnerability item without a CVE or ID');

exec_validator_mandatory_test($csaf, '6.1.27.8');

done_testing;
