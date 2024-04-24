#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(exec_validator_mandatory_test);
use CSAF;

# 6.1.27.3 Vulnerabilities

# It MUST be tested that the element /vulnerabilities does not exist.

# The relevant value for /document/category is:

#   csaf_informational_advisory

# The relevant path for this test is:

#   /vulnerabilities

# Fail test:

#   "vulnerabilities": [
#     {
#       "title": "A vulnerability item that SHALL NOT exist"
#     }
#   ]

my $csaf = CSAF->new;

$csaf->document->title('Mandatory test: 6.1.27.3');
$csaf->document->category('csaf_informational_advisory');
$csaf->document->publisher(category => 'vendor', name => 'CSAF', namespace => 'https://csaf.io');

my $tracking = $csaf->document->tracking(
    id                   => 'CSAF:2023-001',
    status               => 'final',
    version              => '1.0.0',
    initial_release_date => 'now',
    current_release_date => 'now'
);

my $vulns = $csaf->vulnerabilities;
my $vuln  = $vulns->add(title => 'A vulnerability item that SHALL NOT exist');

exec_validator_mandatory_test($csaf, '6.1.27.3');

done_testing;
