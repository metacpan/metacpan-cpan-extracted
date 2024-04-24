#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(exec_validator_mandatory_test);
use CSAF;

# 6.1.18 Released Revision History

# It MUST be tested that no item of the revision history has a number of 0 or 0.y.z when the document status is final or interim.

# The relevant path for this test is:

#   /document/tracking/revision_history[]/number

# Fail test:

#     "tracking": {
#       // ...
#       "revision_history": [
#         {
#           "date": "2021-05-17T10:00:00.000Z",
#           "number": "0",
#           "summary": "First draft"
#         },
#         {
#           "date": "2021-07-21T10:00:00.000Z",
#           "number": "1",
#           "summary": "Initial version."
#         }
#       ],
#       "status": "final",
#       "version": "1"
#     }

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

$tracking->revision_history->add(date => 'now', summary => 'First draft',      number => '0');
$tracking->revision_history->add(date => 'now', summary => 'Initial version.', number => '1');

exec_validator_mandatory_test($csaf, '6.1.18');

done_testing;
