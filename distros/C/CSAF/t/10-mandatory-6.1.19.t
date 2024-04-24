#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(exec_validator_mandatory_test);
use CSAF;

# 6.1.19 Revision History Entries for Pre-release Versions

# It MUST be tested that no item of the revision history has a number which includes pre-release information.

# The relevant path for this test is:

#   /document/tracking/revision_history[]/number

# Fail test:

#     "revision_history": [
#       {
#         "date": "2021-04-22T10:00:00.000Z",
#         "number": "1.0.0-rc",
#         "summary": "Release Candidate for initial version."
#       },
#       {
#         "date": "2021-04-23T10:00:00.000Z",
#         "number": "1.0.0",
#         "summary": "Initial version."
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

$tracking->revision_history->add(
    date    => 'now',
    summary => 'Release Candidate for initial version.',
    number  => '1.0.0-rc'
);
$tracking->revision_history->add(date => 'now', summary => 'Initial version.', number => '1.0.0');

exec_validator_mandatory_test($csaf, '6.1.19');

done_testing;
