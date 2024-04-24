#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(exec_validator_mandatory_test);
use CSAF;

# 6.1.30 Latest Document Version

# It MUST be tested that all elements of type /$defs/version_t follow either integer versioning or semantic versioning homogeneously within the same document.

# The relevant paths for this test are:

#  /document/tracking/revision_history[]/number
#  /document/tracking/version

# Fail test:

#   "tracking": {
#     // ...
#     "revision_history": [
#       {
#         "date": "2021-07-21T09:00:00.000Z",
#         "number": "1.0.0",
#         "summary": "Initial version."
#       },
#       {
#         "date": "2021-07-21T10:00:00.000Z",
#         "number": "2",
#         "summary": "Second version."
#       }
#     ],
#     // ...
#     "version": "2"
#   }

my $csaf = CSAF->new;

$csaf->document->title('Base CSAF Document');
$csaf->document->category('csaf_security_advisory');
$csaf->document->publisher(category => 'vendor', name => 'CSAF', namespace => 'https://csaf.io');

my $tracking = $csaf->document->tracking(
    id                   => 'CSAF:2023-001',
    status               => 'final',
    version              => '2',
    initial_release_date => 'now',
    current_release_date => 'now'
);

$tracking->revision_history->add(date => 'now', summary => 'Initial version.', number => '1.0.0');
$tracking->revision_history->add(date => 'now', summary => 'Second version.',  number => '2');

exec_validator_mandatory_test($csaf, '6.1.30');

done_testing;
