#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(exec_validator_mandatory_test);
use CSAF;

# 6.1.22 Multiple Definition in Revision History

# It MUST be tested that items of the revision history do not contain the same version number.

# The relevant path for this test is:

#   /document/tracking/revision_history

# Fail test:

#    "revision_history": [
#       {
#         "date": "2021-07-20T10:00:00.000Z",
#         "number": "1",
#         "summary": "Initial version."
#       },
#       {
#         "date": "2021-07-21T10:00:00.000Z",
#         "number": "1",
#         "summary": "Some other changes."
#       }
#     ]

my $csaf = CSAF->new;

$csaf->document->title('Base CSAF Document');
$csaf->document->category('csaf_security_advisory');
$csaf->document->publisher(category => 'vendor', name => 'CSAF', namespace => 'https://csaf.io');

my $tracking = $csaf->document->tracking(
    id                   => 'CSAF:2023-001',
    status               => 'final',
    version              => '1.0.0',
    initial_release_date => 'now',
    current_release_date => 'now'
);

$tracking->revision_history->add(date => 'now', summary => 'Initial version.',    number => '1');
$tracking->revision_history->add(date => 'now', summary => 'Some other changes.', number => '1');

exec_validator_mandatory_test($csaf, '6.1.22');

done_testing;
