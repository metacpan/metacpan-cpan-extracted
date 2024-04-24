#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(exec_validator_mandatory_test);
use CSAF;

# 6.1.16 Latest Document Version

# It MUST be tested that document version has the same value as the the number in the last item of Revision History when it is sorted ascending by date. Build metadata is ignored in the comparison. Any pre-release part is also ignored if the document status is draft.

# The relevant path for this test is:

#   /document/tracking/version

# Fail test:

#   "tracking": {
#     // ...
#     "revision_history": [
#       {
#         "date": "2021-07-21T09:00:00.000Z",
#         "number": "1",
#         "summary": "Initial version."
#       },
#       {
#         "date": "2021-07-21T10:00:00.000Z",
#         "number": "2",
#         "summary": "Second version."
#       }
#     ],
#     // ...
#     "version": "1"
#   }

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

$tracking->revision_history->add(date => 'now', summary => 'Initial version.', number => '1');
$tracking->revision_history->add(date => 'now', summary => 'Second version.',  number => '2');

exec_validator_mandatory_test($csaf, '6.1.16');

done_testing;
