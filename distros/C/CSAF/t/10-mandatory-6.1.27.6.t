#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(exec_validator_mandatory_test);
use CSAF;

# 6.1.27.6 Product Status

# For each item in /vulnerabilities it MUST be tested that the element product_status exists.

# The relevant value for /document/category is:

#   csaf_security_advisory

# The relevant path for this test is:

#   /vulnerabilities[]/product_status

# Fail test:

#   "vulnerabilities": [
#     {
#       "title": "A vulnerability item without a product status"
#     }
#   ]

my $csaf = CSAF->new;

$csaf->document->title('Mandatory test: 6.1.27.6');
$csaf->document->category('csaf_security_advisory');
$csaf->document->publisher(category => 'vendor', name => 'CSAF', namespace => 'https://csaf.io');

my $tracking = $csaf->document->tracking(
    id                   => 'CSAF:2023-001',
    status               => 'final',
    version              => '1.0.0',
    initial_release_date => 'now',
    current_release_date => 'now'
);

my $vulns = $csaf->vulnerabilities;
my $vuln  = $vulns->add(title => 'A vulnerability item without a product status');

exec_validator_mandatory_test($csaf, '6.1.27.6');

done_testing;
