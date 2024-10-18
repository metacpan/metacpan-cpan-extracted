#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use CSAF;
use Test::CSAF qw(exec_validator_optional_test);

# 6.2.4 Build Metadata in Revision History

# For each item in revision history it MUST be tested that number does not include build metadata.

# The relevant path for this test is:

#   /document/tracking/revision_history[]/number

# Fail test:

#    "revision_history": [
#      {
#        "date": "2021-04-23T10:00:00.000Z",
#        "number": "1.0.0+exp.sha.ac00785",
#        "summary": "Initial version."
#      }
#    ]

my $csaf = CSAF->new;

$csaf->document->title('Base CSAF Document');
$csaf->document->category('csaf_security_advisory');
$csaf->document->publisher(category => 'vendor', name => 'CSAF', namespace => 'https://csaf.io');

my $tracking = $csaf->document->tracking(
    id                   => 'CSAF:2023-001',
    status               => 'final',
    version              => '1',
    initial_release_date => 'now',
    current_release_date => 'now'
);

$tracking->revision_history->add(date => 'now', summary => 'Initial version.', number => '1.0.0+exp.sha.ac00785"');

exec_validator_optional_test($csaf, '6.2.4');

done_testing;
