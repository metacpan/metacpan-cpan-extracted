#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(exec_validator_mandatory_test);
use CSAF;

# 6.1.27.1 Document Notes

# It MUST be tested that at least one item in /document/notes exists which has a category of description, details, general or summary.

# The relevant values for /document/category are:

#   csaf_informational_advisory
#   csaf_security_incident_response

# The relevant path for this test is:

#   /document/notes

# Fail test:

#   "notes": [
#     {
#       "category": "legal_disclaimer",
#       "text": "The CSAF document is provided to You \"AS IS\" and \"AS AVAILABLE\" and with all faults and defects without warranty of any kind.",
#       "title": "Terms of Use"
#     }
#   ]

my $csaf = CSAF->new;

$csaf->document->title('Mandatory test: 6.1.27.1');
$csaf->document->publisher(category => 'vendor', name => 'CSAF', namespace => 'https://csaf.io');

my $tracking = $csaf->document->tracking(
    id                   => 'CSAF:2023-001',
    status               => 'final',
    version              => '1.0.0',
    initial_release_date => 'now',
    current_release_date => 'now'
);

$csaf->document->notes->add(
    category => 'legal_disclaimer',
    title    => 'Terms of Use',
    text     =>
        'The CSAF document is provided to You \"AS IS\" and \"AS AVAILABLE\" and with all faults and defects without warranty of any kind.',
);

foreach my $category (qw(csaf_informational_advisory csaf_security_incident_response)) {

    $csaf->document->category($category);

    exec_validator_mandatory_test($csaf, '6.1.27.1');

}

done_testing;
