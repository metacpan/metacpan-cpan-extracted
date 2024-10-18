#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(exec_validator_mandatory_test);
use CSAF;

# 6.1.27.2 Document References

# It MUST be tested that at least one item in /document/references exists that has links to an external source.

# The relevant values for /document/category are:

#   csaf_informational_advisory
#   csaf_security_incident_response

# The relevant path for this test is:

#   /document/references

# Fail test:

#   "references": [
#     {
#       "category": "self",
#       "summary": "The canonical URL.",
#       "url": "https://example.com/security/data/csaf/2021/OASIS_CSAF_TC-CSAF_2_0-2021-6-1-27-02-01.json"
#     }
#   ]

my $csaf = CSAF->new;

$csaf->document->title('Mandatory test: 6.1.27.2');
$csaf->document->publisher(category => 'vendor', name => 'CSAF', namespace => 'https://csaf.io');

my $tracking = $csaf->document->tracking(
    id                   => 'CSAF:2023-001',
    status               => 'final',
    version              => '1.0.0',
    initial_release_date => 'now',
    current_release_date => 'now'
);

$csaf->document->references->add(
    url      => 'https://example.com/security/data/csaf/2021/OASIS_CSAF_TC-CSAF_2_0-2021-6-1-27-02-01.json',
    summary  => 'The canonical URL.',
    category => 'self'
);

foreach my $category (qw(csaf_informational_advisory csaf_security_incident_response)) {

    $csaf->document->category($category);

    exec_validator_mandatory_test($csaf, '6.1.27.2');

}

done_testing;
