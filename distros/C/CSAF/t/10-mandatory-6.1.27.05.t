#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(exec_validator_mandatory_test);
use CSAF;

# 6.1.27.5 Vulnerability Notes

# For each item in /vulnerabilities it MUST be tested that the element notes exists.

# The relevant values for /document/category are:

#   csaf_security_advisory
#   csaf_vex

# The relevant path for this test is:

#   /vulnerabilities[]/notes

# Fail test:

#   "vulnerabilities": [
#     {
#       "title": "A vulnerability item without a note"
#     }
#   ]

my $csaf = CSAF->new;

$csaf->document->title('Mandatory test: 6.1.27.5');
$csaf->document->publisher(category => 'vendor', name => 'CSAF', namespace => 'https://csaf.io');

my $tracking = $csaf->document->tracking(
    id                   => 'CSAF:2023-001',
    status               => 'final',
    version              => '1.0.0',
    initial_release_date => 'now',
    current_release_date => 'now'
);

my $vulns = $csaf->vulnerabilities;
my $vuln  = $vulns->add(title => 'A vulnerability item without a note');

foreach my $category (qw(csaf_security_advisory csaf_vex)) {

    $csaf->document->category($category);

    exec_validator_mandatory_test($csaf, '6.1.27.5');

}

done_testing;
